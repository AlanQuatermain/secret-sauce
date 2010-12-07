//
//  main.m
//  backtrace
//
//  Created by Jim Dovey on 10-12-04.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <mach/task.h>
#import <mach/mach_error.h>
#import "VMUSampler.h"
#import "VMUMachTaskContainer.h"
#import "VMUBacktrace.h"
#import "VMUSymbolicator.h"
#import "VMUSymbol.h"
#import "VMUSymbolOwner.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSMutableString * output = [NSMutableString string];
    
    pid_t procID = (pid_t)[[NSUserDefaults standardUserDefaults] integerForKey: @"ProcID"];
    NSLog( @"procID = %d", (int) procID );
    
    VMUMachTaskContainer * container = [VMUMachTaskContainer machTaskContainerWithPid: procID];
    NSLog( @"Mach task container = %@", container );
    if ( container == nil )
    {
        [pool drain];
        return ( 1 );
    }
    
    VMUSymbolicator * symbolicator = [VMUSymbolicator symbolicatorForMachTaskContainer: container];
    NSArray * samples = [VMUSampler sampleAllThreadsOfTask: [container task]
                                          withSymbolicator: symbolicator];
    NSUInteger i = 0;
    for ( VMUBacktrace * backtrace in samples )
    {
        [output appendFormat: @"Thread %d (%#x)", i, [backtrace thread]];
        //if ( [backtrace thread] == exc_thread )
        //    [output appendString: @" Crashed"];
        [output appendString: @":\n"];
        
        pointer_t * trace = [backtrace backtrace];
        for ( int j = 0; j < [backtrace backtraceLength]; j++ )
        {
            VMUSymbol * symbol = [symbolicator symbolForAddress: trace[j]];
            VMUSymbolOwner * owner = [symbolicator symbolOwnerForAddress: trace[j]];
            [output appendFormat: @"%d\t%-030s %p : %@\n", j, [[owner name] UTF8String], trace[j], [symbol name]];
        }
        
        // empty line between items
        [output appendString: @"\n"];
        
        i++;
    }
    
    NSLog( @"Backtrace:\n%@", output );
    
    [pool drain];
    return 0;
}

