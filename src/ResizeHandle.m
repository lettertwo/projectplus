//
//  ResizeHandle.m
//  ProjectPlus
//
//  Created by Eric Eldredge on 10/13/10.
//  Copyright 2010 HZDG. All rights reserved.
//

#import "ResizeHandle.h"


@implementation ResizeHandle


- (id)init
{
	if((self = [super initWithFrame:NSMakeRect(0, 0, 16.0, 15.0)]))
	{
		icon = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 15.0)];
		[icon lockFocus];

		// TODO: figure out how to make a gradient fill.
		// TODO: Draw right border of button.
		// [[NSColor blackColor] setFill];
		// NSRectFill(NSMakeRect(0, 0, 16, 15));
	
		// DO drawing here.
		float color = 122/255.;
		[[NSColor colorWithCalibratedRed:color green:color blue:color alpha:1.] setFill];
		NSRectFill(NSMakeRect(4, 4, 1.0, 7.0));
		NSRectFill(NSMakeRect(7, 4, 1.0, 7.0));
		NSRectFill(NSMakeRect(10, 4, 1.0, 7.0));
	
		[icon unlockFocus];

		[self setImage:icon];
	}
	return self;
}

- (id)initWithView:(NSView *)aView
{
	if (self = [self init])
	{
		view = aView;
	}
	return self;
}

- (void)dealloc
{
	[icon release];
	[super dealloc];
}



// TODO: Why are these necessary to keep mouseDragged handling working?
- (void)mouseDown:(NSEvent *)anEvent { }
- (void)mouseUp:(NSEvent *)anEvent { }



- (void)mouseDragged:(NSEvent *)anEvent
{
	NSRect frame = [view frame];
	frame.size.width += [anEvent deltaX];
	
	[view setFrame: frame];
}

@end
