#import "JRSwizzle.h"
#import "ResizeHandle.h"

@interface ProjectTree : NSObject
+ (BOOL)preserveTreeState;
@end

@implementation NSWindowController (OakProjectController)
- (void)expandItems:(NSArray*)items inOutlineView:(NSOutlineView*)outlineView toState:(NSDictionary*)treeState
{
	unsigned int itemCount = [items count];

	for(unsigned int index = 0; index < itemCount; index += 1)
	{
		NSDictionary *item = [items objectAtIndex:index];

		if(not [item objectForKey:@"children"])
			continue; // We are only interested in directories

		if(NSDictionary *treeItem = [treeState objectForKey:[item objectForKey:@"displayName"]])
		{
			if([[treeItem objectForKey:@"isExpanded"] boolValue])
				[outlineView expandItem:item];
			
			if([[treeItem objectForKey:@"subItems"] count])
				[self expandItems:[item objectForKey:@"children"] inOutlineView:outlineView toState:[treeItem objectForKey:@"subItems"]];
		}
	}
}

static int compareFrameOriginX(id viewA, id viewB, void *context)
{
    float v1 = [viewA frame].origin.x;
    float v2 = [viewB frame].origin.x;

	if (v1 < v2) {
        return NSOrderedAscending;
	} else if (v1 > v2) {
        return NSOrderedDescending;
	}

	return NSOrderedSame;
}

- (void)ProjectTree_adjustLayout
{
	NSOutlineView *outlineView = [self valueForKey:@"outlineView"];
	NSView *projectView = [[[outlineView superview] superview] superview];
	NSScrollView *scrollView = nil;
	
	// TODO: Set background color.
	// TODO: Add background color preference.
	// [outlineView setBackgroundColor: [NSColor lightGrayColor]];
	
    // Gather buttons
    NSMutableArray *btns = [[NSMutableArray alloc] init];
	NSArray *subviews = [projectView subviews];
	for (unsigned int i = 0; i < [subviews count]; i++) {
        id aView = [subviews objectAtIndex:i];
        if ([aView isKindOfClass:[NSButton class]] && [aView frame].origin.y < 1)
		{
            [btns addObject:aView];
        } 
		else if ([aView isKindOfClass:[NSScrollView class]])
		{
            scrollView = (NSScrollView *)aView;
        }
    }
	
 	[btns sortUsingFunction:compareFrameOriginX context:nil];
	
	// Adjust outlineView frame
    if (scrollView)
	{
		NSRect aRect = [scrollView frame];
		aRect.origin.x -= 1;
		aRect.origin.y -= 8;
		aRect.size.width += 1;
		aRect.size.height += 9;
        [scrollView setFrame:aRect];
		
        NSOutlineView *realOutlineView = [scrollView documentView];
        NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:12];
        NSLayoutManager *layoutManager = [NSLayoutManager new]; 
        [realOutlineView setRowHeight:[layoutManager defaultLineHeightForFont:font]];
        [layoutManager release];
        [realOutlineView setIntercellSpacing:NSMakeSize (6.0, 4.0)];
        [realOutlineView reloadData];
    }
	
	// Arrange buttons
	// TODO: Handle sidebar on right case.
	float nx = -1;
	for (unsigned int i = 0; i < [btns count]; i++)
	{
		NSView *button = [btns objectAtIndex:i];
		NSRect buttonFrame = [button frame];
		buttonFrame.origin.x = nx;
		buttonFrame.origin.y -= 1;
		buttonFrame.size.height -= 4;
		nx += buttonFrame.size.width - 1;
		
		[button setAutoresizingMask:NSViewMaxXMargin];
		[button setFrame:buttonFrame];
	}
    [btns release];

	// Add resize handle.
	ResizeHandle *resizeHandle = [[ResizeHandle alloc] initWithView: projectView];
	
	NSRect handleRect = [resizeHandle frame];

	// TODO: Handle sidebar on right case.
	handleRect.origin.x = [projectView frame].size.width - handleRect.size.width;

	[resizeHandle setAutoresizingMask:NSViewMinXMargin];
	[resizeHandle setFrame:handleRect];
	
	// TODO: Handle sidebar on right case?
	[projectView addSubview:resizeHandle];
	[projectView setNeedsDisplay:YES];
	[projectView setAutoresizingMask:(NSViewWidthSizable + NSViewMaxYMargin)];

}

- (void)ProjectTree_windowDidLoad
{
	[self ProjectTree_windowDidLoad];
	[self ProjectTree_adjustLayout];
	NSOutlineView *outlineView = [self valueForKey:@"outlineView"];
	[outlineView reloadData];
	
	if(not [ProjectTree preserveTreeState])
		return;

	NSDictionary *treeState = [[NSDictionary dictionaryWithContentsOfFile:[self valueForKey:@"filename"]] objectForKey:@"treeState"];
	if(treeState)
	{
		NSArray *rootItems         = [self valueForKey:@"rootItems"];
		[self expandItems:rootItems inOutlineView:outlineView toState:treeState];
	}
}

- (NSDictionary*)outlineView:(NSOutlineView*)outlineView stateForItems:(NSArray*)items
{
	NSMutableDictionary *treeState = [NSMutableDictionary dictionaryWithCapacity:3];
	unsigned int itemCount = [items count];

	for(unsigned int index = 0; index < itemCount; index += 1)
	{
		NSDictionary *item = [items objectAtIndex:index];
		if([outlineView isItemExpanded:item])
		{
			NSDictionary *subTreeState = [self outlineView:outlineView stateForItems:[item objectForKey:@"children"]];
			[treeState setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"isExpanded",
																								 subTreeState,@"subItems",
																								 nil] forKey:[item objectForKey:@"displayName"]];
		}
	}	
	
	return treeState;
}

- (BOOL)ProjectTree_writeToFile:(NSString*)fileName
{
	BOOL result = [self ProjectTree_writeToFile:fileName];
	if(result && [ProjectTree preserveTreeState])
	{
		NSMutableDictionary *project = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
		NSDictionary *treeState      = [self outlineView:[self valueForKey:@"outlineView"] stateForItems:[self valueForKey:@"rootItems"]];
		[project setObject:treeState forKey:@"treeState"];
		result = [project writeToFile:fileName atomically:NO];
	}
	return result;
}
@end

@implementation ProjectTree
+ (void)load
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																					[NSNumber numberWithBool:YES],@"ProjectPlus Preserve Tree",
																					nil]];

	[NSClassFromString(@"OakProjectController") jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(ProjectTree_windowDidLoad) error:NULL];
	[NSClassFromString(@"OakProjectController") jr_swizzleMethod:@selector(writeToFile:) withMethod:@selector(ProjectTree_writeToFile:) error:NULL];
}

+ (BOOL)preserveTreeState;
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ProjectPlus Preserve Tree"];
}
@end
