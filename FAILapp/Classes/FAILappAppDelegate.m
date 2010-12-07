//
//  FAILappAppDelegate.m
//  FAILapp
//
//  Created by Jim Dovey on 10-11-28.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "FAILappAppDelegate.h"

@implementation FAILappAppDelegate

@synthesize window;

- (void) omgFAIL
{
	id FAIL = (id)1;
	[FAIL release];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	[self performSelector: @selector(omgFAIL) withObject: nil afterDelay: 2.0];
}

@end
