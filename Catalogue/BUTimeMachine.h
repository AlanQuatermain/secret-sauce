/*
 *  BUTimeMachine.h
 *  Catalogue
 *
 *  Created by Jim Dovey on 10-12-08.
 *  Copyright 2010 Kobo Inc. All rights reserved.
 *
 */

#ifndef __BU_TIME_MACHINE_H__
#define __BU_TIME_MACHINE_H__

///////////////////////////////////////////////////////////////////////
// Link with /System/Library/PrivateFrameworks/Backup.framework

#include <sys/cdefs.h>
#include <CoreFoundation/CoreFoundation.h>

// event callback types
typedef void (*BUTimeMachineStartedFromDockCallBack)(void);
typedef void (*BUTimeMachineDismissedCallBack)(void * context);
typedef void (*BUTimeMachineRestoreCallBack)(void * context, CFURLRef backupURL, CFURLRef liveURL,
                                             Boolean restoreAll, CFDictionaryRef options);
typedef void (*BUTimeMachineRequestSnapshotCallBack)(void * context, CFURLRef backupURL);
typedef void (*BUTimeMachineActivateSnapshotCallBack)(void * context, CFURLRef backupURL, CGRect bounds);
typedef void (*BUTimeMachineDeactivateSnapshotCallBack)(void * context, CFURLRef backupURL);

__BEGIN_DECLS

// start the time machine user interface (in response to a 'started from dock' callback)
void BUStartTimeMachine( int windowNumber, CFURLRef currentDataURL, int flags );

// invalidate all snapshot images
void BUInvalidateAllSnapshotImages( void );

// completion functions for async event handlers
void BUActivatedSnapshot( int windowNumber, CFURLRef backupURL );
void BUDeactivatedSnapshot( int windowNumber, CFURLRef backupURL );
void BUUpdateSnapshotImage( int windowNumber, CFURLRef backupURL );

// setting callbacks
void BURegisterStartTimeMachineFromDock( BUTimeMachineStartedFromDockCallBack callback );
void BURegisterTimeMachineDismissed( void * context, BUTimeMachineDismissedCallBack callback );
void BURegisterTimeMachineRestore( void * context, BUTimeMachineRestoreCallBack callback );
void BURegisterRequestSnapshotImage( void * context, BUTimeMachineRequestSnapshotCallBack callback );
void BURegisterActivateSnapshot( void * context, BUTimeMachineActivateSnapshotCallBack callback );
void BURegisterDeactivateSnapshot( void * context, BUTimeMachineDeactivateSnapshotCallBack callback );

__END_DECLS

#endif  /* __BU_TIME_MACHINE_H__ */
