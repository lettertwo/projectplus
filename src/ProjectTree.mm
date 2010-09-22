#import "JRSwizzle.h"

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


- (void)ProjectTree_windowDidLoad
{
	[self ProjectTree_windowDidLoad];

	if(not [ProjectTree preserveTreeState])
		return;

	[[self valueForKey:@"outlineView"] reloadData];

	NSOutlineView *outlineView = [self valueForKey:@"outlineView"];
	[outlineView setIntercellSpacing:NSMakeSize(4, 6)];
	
	/* TODO: Figure out how to adjust the positioning of the subviews of the project view.
	The project view appears to contain the outline view and the four buttons aligned underneath the view. */

	// TODO: Figure out a more straightforward way to access the project view.
	NSView *projectView = [[[outlineView superview] superview] superview];

	NSArray *array = [projectView subviews];
	for(unsigned int i = 0; i < [array count]; i += 1)
	{
// 		id object = [array objectAtIndex:i];
// 		
// 		NSRect frame = [object frame];
// 		
// NSLog(@">>> %@", frame);
		
// [frame setOrigin:NSMakePoint([[frame origin] x] + 100, [[frame origin] y])];
// NSPoint origin = NSMakePoint(100, 100);
// [frame setOrigin:origin];
// [object setFrame:frame];

	}
	
	
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
