//
//  SugoExceptionHandler.m
//  HelloSugo
//
//  Created by Sam Green on 7/28/15.
//  Copyright (c) 2015 Sugo. All rights reserved.
//

#import "SugoExceptionHandler.h"
#import "Sugo.h"
#import "MPLogger.h"

@interface SugoExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, strong) NSHashTable *sugoInstances;

@end

@implementation SugoExceptionHandler

+ (instancetype)sharedHandler {
    static SugoExceptionHandler *gSharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gSharedHandler = [[SugoExceptionHandler alloc] init];
    });
    return gSharedHandler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create a hash table of weak pointers to sugo instances
        _sugoInstances = [NSHashTable weakObjectsHashTable];
        
        // Save the existing exception handler
        _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
        // Install our handler
        NSSetUncaughtExceptionHandler(&mp_handleUncaughtException);
    }
    return self;
}

- (void)addSugoInstance:(Sugo *)instance {
    NSParameterAssert(instance != nil);
    
    [self.sugoInstances addObject:instance];
}

static void mp_handleUncaughtException(NSException *exception) {
    SugoExceptionHandler *handler = [SugoExceptionHandler sharedHandler];
    
    // Archive the values for each Sugo instance
    for (Sugo *instance in handler.sugoInstances) {
        [instance archive];
    }
    
    MPLogError(@"Encountered an uncaught exception. All Sugo instances were archived.");
    
    if (handler.defaultExceptionHandler) {
        // Ensure the existing handler gets called once we're finished
        handler.defaultExceptionHandler(exception);
    }
}

@end
