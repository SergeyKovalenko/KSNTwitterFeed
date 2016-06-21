//
// Created by Sergey Kovalenko on 10/31/14.
// Copyright (c) 2014 Windmill. All rights reserved.
//

#import "KSNObservable.h"
#import <objc/runtime.h>

static NSMapTable *createSignaturesForProtocolMethods(BOOL isRequiredMethod, Protocol *aProtocol)
{
    NSMapTable *signatures = [NSMapTable strongToStrongObjectsMapTable];
    unsigned int count;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(aProtocol, isRequiredMethod, YES, &count);

    for (unsigned i = 0; i < count; i++)
    {
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:methods[i].types];
        SEL selector = methods[i].name;
        [signatures setObject:signature forKey:NSStringFromSelector(selector)];
    }
    free(methods);
    return signatures;
}

@implementation KSNObservable
{
    NSMapTable *_protocolRequiredSignatures;
    NSMapTable *_protocolOptionalSignatures;

    NSHashTable *_listeners;

    Protocol *_protocol;
    NSRecursiveLock *_lock;
}

@synthesize showDebugLogs = _showDebugLogs;

- (instancetype)initWithProtocol:(Protocol *)observableProtocol
{
    if (self)
    {
        _protocol = observableProtocol;
        _protocolRequiredSignatures = createSignaturesForProtocolMethods(YES, observableProtocol);
        _protocolOptionalSignatures = createSignaturesForProtocolMethods(NO, observableProtocol);

        _listeners = [NSHashTable weakObjectsHashTable];
        _showDebugLogs = NO;
        _lock = [[NSRecursiveLock alloc] init];
        _lock.name = @"KSNObservable.Lock";
    }
    return self;
}

#pragma mark - Private

#pragma mark - Public

- (void)addListener:(id)listener
{
    NSParameterAssert([listener conformsToProtocol:_protocol]);
    [_lock lock];
    [_listeners addObject:listener];
    [_lock unlock];
}

- (void)removeListener:(id)listener
{
    [_lock lock];
    [_listeners removeObject:listener];
    [_lock unlock];
}

- (void)removeAllListeners
{
    [_lock lock];
    [_listeners removeAllObjects];
    [_lock unlock];
}

#pragma mark - NSProxy

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([_protocolRequiredSignatures objectForKey:NSStringFromSelector(invocation.selector)])
    {
        [_lock lock];
        for (id listener in [_listeners allObjects])
        {
            [invocation invokeWithTarget:listener];
            if (self.showDebugLogs)
            {
                NSLog(@"forwardInvocation %@ to %@", NSStringFromSelector(invocation.selector), listener);
            }
        }
        [_lock unlock];
    }
    else if ([_protocolOptionalSignatures objectForKey:NSStringFromSelector(invocation.selector)])
    {
        [_lock lock];
        for (id listener in [_listeners allObjects])
        {
            if ([listener respondsToSelector:invocation.selector])
            {
                [invocation invokeWithTarget:listener];
                if (self.showDebugLogs)
                {
                    NSLog(@"forwardInvocation %@ to %@", NSStringFromSelector(invocation.selector), listener);
                }
            }
        }
        [_lock unlock];
    }
    else
    {
        [super forwardInvocation:invocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [_protocolRequiredSignatures objectForKey:NSStringFromSelector(sel)] ?: [_protocolOptionalSignatures objectForKey:NSStringFromSelector(sel)];
}

@end

@implementation KSNDelegate

- (instancetype)initWithProtocol:(Protocol *)observableProtocol delegate:(id)delegate
{
    self = [super initWithProtocol:observableProtocol];
    if (self)
    {
        [self addListener:delegate];
    }
    return self;
}

@end