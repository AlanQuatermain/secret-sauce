//
//  FAILappAppDelegate.h
//  FAILapp
//
//  Created by Jim Dovey on 10-11-28.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FAILappAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
