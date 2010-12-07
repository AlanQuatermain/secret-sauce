#import <Foundation/Foundation.h>
#import <mach/message.h>
#import <mach/mach_port.h>
#import <mach/exc.h>
#import <mach/exc_server.h>
#import <mach/task.h>
#import <mach/thread_act.h>
#import <mach/thread_info.h>
#import <mach/mach_error.h>
#import <dispatch/dispatch.h>
#import <Kernel/mach/exc_server.h>
#import "VMUSymbolicator.h"
#import "VMUMachTaskContainer.h"
#import "VMUSampler.h"
#import "VMUBacktrace.h"
#import "VMUSymbol.h"
#Import "VMUSymbolOwner.h"

#define MACH_CHECK_ERROR_RET(name, ret) \
if ( ret != KERN_SUCCESS ) { \
	mach_error(#name, ret); \
	return (ret); \
}

#define MACH_CHECK_ERROR(name, ret) \
if ( ret != KERN_SUCCESS ) { \
	mach_error(#name, ret); \
	return; \
}

// Could make this dynamic by looking for a result of MIG_ARRAY_TOO_LARGE
#define HANDLER_COUNT 64

typedef struct _ExceptionPorts {
    mach_msg_type_number_t  maskCount;
    exception_mask_t        masks[HANDLER_COUNT];
    exception_handler_t     handlers[HANDLER_COUNT];
    exception_behavior_t    behaviors[HANDLER_COUNT];
    thread_state_flavor_t   flavors[HANDLER_COUNT];
} ExceptionPorts;

static ExceptionPorts * gOldHandlerData;
static task_t gTargetTask = MACH_PORT_NULL;
static NSMutableString * gBacktraceLog = nil;

#pragma mark -

static void backtrace_log( void )
{
    if ( [gBacktraceLog length] == 0 )
        return; // no log to write
    
    // write the crash report somewhere
    NSString * path = @"/Users/Shared/TestCrashReport.crash";
    NSError * error = nil;
    
    if ( [gBacktraceLog writeToFile: path atomically: YES encoding: NSUTF8StringEncoding error: &error] == NO )
    {
        NSLog( @"Failed to write crash report: %@", error );
    }
}

static void backtrace_task( task_t task, thread_t exc_thread, exception_data_t code, mach_msg_type_number_t codeCnt )
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    @try
    {
        if ( gBacktraceLog == nil )
            gBacktraceLog = [NSMutableString new];
        else
            [gBacktraceLog setString: @""];
        
        VMUSymbolicator * symbolicator = [VMUSymbolicator symbolicatorForTask: task];
        NSArray * samples = [VMUSampler sampleAllThreadsOfTask: task
                                              withSymbolicator: symbolicator];
        NSUInteger i = 0;
        for ( VMUBacktrace * backtrace in samples )
        {
            [gBacktraceLog appendFormat: @"Thread %d (%#x)", i, [backtrace thread]];
            if ( [backtrace thread] == exc_thread )
                [gBacktraceLog appendString: @" Crashed"];
            [gBacktraceLog appendString: @":\n"];
            
            pointer_t * trace = [backtrace backtrace];
            for ( int j = 0; j < [backtrace backtraceLength]; j++ )
            {
                VMUSymbol * symbol = [symbolicator symbolForAddress: trace[j]];
                VMUSymbolOwner * owner = [symbolicator symbolOwnerForAddress: trace[j]];
                [gBacktraceLog appendFormat: @"%d\t%-30s %p : %@\n", j, [[owner name] UTF8String], trace[j], [symbol name]];
            }
            
            // empty line between items
            [gBacktraceLog appendString: @"\n"];
            
            i++;
        }
    }
    @catch (NSException * e)
    {
    }
    @finally
    {
        [pool drain];
    }
}

#pragma mark -

kern_return_t forward_exception( thread_t thread, mach_port_t task, exception_type_t exception,
                                 exception_data_t code, mach_msg_type_number_t codeCount, int *flavor,
                                 thread_state_t old_state, mach_msg_type_number_t old_stateCnt,
                                 thread_state_t new_state, mach_msg_type_number_t *new_stateCnt )
{
    kern_return_t kr;
    unsigned int portIndex;
    
    mach_port_t port;
    exception_behavior_t behaviour;
    int thread_flavor;
    
    thread_state_data_t thread_state;
    mach_msg_type_number_t thread_state_count;
    
    for ( portIndex = 0; portIndex < gOldHandlerData->maskCount; portIndex++ )
    {
        if ( gOldHandlerData->masks[portIndex] & (1 << exception) )
        {
            // This handler wants the exception
            break;
        }
    }
    
    if ( portIndex >= gOldHandlerData->maskCount )
    {
        fprintf( stderr, "No handler for exception type %d. Not forwarding.\n" );
        return ( KERN_FAILURE );
    }
    
    port = gOldHandlerData->handlers[portIndex];
    behaviour = gOldHandlerData->behaviors[portIndex];
    flavor = gOldHandlerData->flavors[portIndex];
    
    fprintf( stderr, "Forwarding exception, port = %#x, behaviour = %d, flavor = %d\n", port, behaviour, flavor );
    
    if ( (behaviour != EXCEPTION_DEFAULT) && 
         (old_state == NULL) )
    {
        thread_state_count = THREAD_STATE_MAX;
        kr = thread_get_state( thread, &thread_flavor, thread_state, &thread_state_count );
        MACH_CHECK_ERROR_RET(thread_get_state, kr);
        
        flavor = &thread_flavor;
        old_state = thread_state;
        old_stateCnt = thread_state_count;
        
        new_state = thread_state;
        new_stateCnt = &thread_state_count;
    }
    
    switch ( behaviour )
    {
        case EXCEPTION_DEFAULT:
            fprintf( stderr, "Forwarding to exception_raise\n" );
            kr = exception_raise( port, thread, task, exception, code, codeCount );
            MACH_CHECK_ERROR_RET(exception_raise, kr);
            break;
            
        case EXCEPTION_STATE:
            fprintf( stderr, "Forwarding to exception_raise_state\n" );
            kr = exception_raise_state( port, exception, code, codeCount, flavor, old_state, old_stateCnt, new_state, new_stateCnt );
            MACH_CHECK_ERROR_RET(exception_raise_state, kr);
            break;
            
        case EXCEPTION_STATE_IDENTITY:
            fprintf( stderr, "Forwarding to exception_raise_state_identity\n" );
            kr = exception_raise_state_identity( port, thread, task, exception, code, codeCount, flavor, old_state, old_stateCnt, new_state, new_stateCnt );
            MACH_CHECK_ERROR_RET(exception_raise_state_identity, kr);
            break;
            
        default:
            fprintf( stderr, "forward_exception: unknown beaviour %d\n", behaviour );
            break;
    }
    
    if ( behaviour != EXCEPTION_DEFAULT )
    {
        kr = thread_set_state( thread, *flavor, new_state, *new_stateCnt );
        MACH_CHECK_ERROR_RET(thread_set_state, kr);
    }
    
    return ( KERN_SUCCESS );
}

kern_return_t
catch_exception_raise
(
    mach_port_t exception_port,
    thread_t thread,
    mach_port_t task,
    exception_type_t exception,
    exception_data_t code,
    mach_msg_type_number_t codeCnt
)
{
    kern_return_t kr;
    backtrace_task( task, thread, code, codeCnt );
    
    kr = forward_exception( thread, task, exception, code, codeCnt, NULL, NULL, 0, NULL, 0 );
    return ( kr );
}

kern_return_t
catch_exception_raise_state
(
    mach_port_t exception_port,
    exception_type_t exception,
    exception_data_t code,
    mach_msg_type_number_t codeCnt,
    int *flavor,
    thread_state_t old_state,
    mach_msg_type_number_t old_stateCnt,
    thread_state_t new_state,
    mach_msg_type_number_t *new_stateCnt
)
{
    kern_return_t kr = KERN_SUCCESS;
    backtrace_task( gTargetTask, MACH_PORT_NULL, code, codeCnt );
    
    kr = forward_exception( MACH_PORT_NULL, MACH_PORT_NULL, exception, code, codeCnt, flavor,
                            old_state, old_stateCnt, new_state, new_stateCnt );
    return ( kr );
}

kern_return_t
catch_exception_raise_state_identity
(
    mach_port_t exception_port,
    mach_port_t thread,
    mach_port_t task,
    exception_type_t exception,
    exception_data_t code,
    mach_msg_type_number_t codeCnt,
    int *flavor,
    thread_state_t old_state,
    mach_msg_type_number_t old_stateCnt,
    thread_state_t new_state,
    mach_msg_type_number_t *new_stateCnt
)
{
    kern_return_t kr;
    backtrace_task( task, thread, code, codeCnt );
    
    kr = forward_exception( thread, task, exception, code, codeCnt, flavor, old_state, old_stateCnt,
                            new_state, new_stateCnt );
    return ( kr );
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSNumber * procID = [[NSUserDefaults standardUserDefaults] valueForKey: @"TargetProcessID"];
	VMUMachTaskContainer * container = [VMUMachTaskContainer machTaskContainerWithPid: [procID intValue]];
    gTargetTask = [container task];
	
	mach_port_t exc_catcher_port = MACH_PORT_NULL;
	kern_return_t kr = mach_port_allocate( mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &exc_catcher_port );
	if ( kr != KERN_SUCCESS )
	{
		[pool drain];
		return ( 1 );
	}
	
	kr = mach_port_insert_right( mach_task_self(), exc_catcher_port, exc_catcher_port, MACH_MSG_TYPE_MAKE_SEND );
	if ( kr != KERN_SUCCESS )
	{
		[pool drain];
		return ( 1 );
	}
	
	// wait for stuff to arrive on that port
	dispatch_source_t exc_source = dispatch_source_create( DISPATCH_SOURCE_TYPE_MACH_RECV, exc_catcher_port, 0, dispatch_get_main_queue() );
    
    dispatch_source_set_cancel_handler( exc_source, ^{
        for ( int i = 0; i < gOldHandlerData->maskCount; i++ )
        {
            if ( gOldHandlerData->handlers[i] == MACH_PORT_NULL )
                break;
            task_set_exception_ports( [container task], gOldHandlerData->masks[i], gOldHandlerData->handlers[i],
                                      gOldHandlerData->behaviors[i], gOldHandlerData->flavors[i] );
        }
        mach_port_destroy( mach_task_self(), exc_catcher_port );
    });
	
    dispatch_source_set_event_handler( exc_source, ^{
		mach_msg_header_t *msg, *reply;
		kern_return_t krc;
		
#define MSG_SIZE 512
		msg = alloca(MSG_SIZE);
		reply = alloca(MSG_SIZE);
		
		// read the message
		krc = mach_msg( msg, MACH_RCV_MSG, MSG_SIZE, MSG_SIZE, exc_catcher_port, 0, MACH_PORT_NULL );
		MACH_CHECK_ERROR(mach_msg, krc);
		
		if ( exc_server(msg, reply) == false )
		{
			NSLog( @"exc_server() hated the message" );
			return;
		}
		
		// sending reply to the original receiver
		(void) mach_msg( reply, MACH_SEND_MSG, reply->msgh_size, 0, msg->msgh_local_port, 0, MACH_PORT_NULL );
	});
    
    gOldHandlerData = calloc( 1, sizeof(gOldHandlerData) );
    gOldHandlerData->maskCount = sizeof(gOldHandlerData->masks)/sizeof(gOldHandlerData->masks[0]);
    kr = task_get_exception_ports( [container task], EXC_MASK_ALL, gOldHandlerData->masks, gOldHandlerData->maskCount,
                                   gOldHandlerData->handlers, gOldHandlerData->behaviors, gOldHandlerData->flavors );
    if ( kr != KERN_SUCCESS )
    {
        fprintf( stderr, "Unable to get old task_exception_ports kr = %d (%s)\n", kr, mach_error_string(kr) );
        [pool drain];
        return ( 1 );
    }
    
    // install new exception ports
    kr = task_set_exception_ports( [container task], EXC_MASK_ALL & ~(EXC_MASK_MACH_SYSCALL|EXC_MASK_SYSCALL|EXC_MASK_RPC_ALERT),
                                   exc_catcher_port, EXCEPTION_DEFAULT, THREAD_STATE_NONE );
    if ( kr != KERN_SUCCESS )
    {
        fprintf( stderr, "Unable to set new task_exception_ports kr = %d (%s)\n", kr, mach_error_string(kr) );
        [pool drain];
        return ( 1 );
    }
    
    // handle task death
    mach_port_t death_port = MACH_PORT_NULL;
    mach_port_t old_port = MACH_PORT_NULL;
    kr = mach_port_allocate( mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &death_port );
    kr = mach_port_request_notification( mach_task_self(), [container task], MACH_NOTIFY_DEAD_NAME, 0, death_port, MACH_MSG_TYPE_MAKE_SEND_ONCE, &old_port );

    dispatch_source_t death_source = dispatch_source_create( DISPATCH_SOURCE_TYPE_MACH_RECV, 
                                                             death_port, 0, dispatch_get_main_queue() );

    dispatch_source_set_cancel_handler( death_source, ^{
        mach_port_request_notification( mach_task_self(), [container task], MACH_NOTIFY_DEAD_NAME, 0, old_port, 0, NULL );
        mach_port_destroy( mach_task_self(), death_port );
    });

    dispatch_source_set_event_handler( death_source, ^{
        mach_msg_header_t * msg;
        msg = alloca(MSG_SIZE);
        
        // consume the message (although we know it's a dead name notification)
        (void) mach_msg( msg, MACH_RCV_MSG, MSG_SIZE, MSG_SIZE, death_port, 0, MACH_PORT_NULL );
        
        // the task has gone-- log the crash report
        // we only do this once the app has gone, in case
        // a logged exception isn't fatal
        backtrace_log();
        
        // the task we're watching has shut down, so we can quit now
        dispatch_source_cancel( exc_source );
        dispatch_source_cancel( death_source );
    });
    
    // resume the sources
    dispatch_resume( exc_source );
    dispatch_resume( death_source );
    
    // run the dispatch loop
    dispatch_main();
	
    [pool drain];
    return 0;
}
