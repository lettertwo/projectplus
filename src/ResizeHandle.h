//
//  ResizeHandle.h
//  ProjectPlus
//
//  Created by Eric Eldredge on 10/13/10.
//  Copyright 2010 HZDG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ResizeHandle : NSImageView {
	NSImage* icon;
	NSView* view;
}

- (id)initWithView:(NSView *)aView;

@end
