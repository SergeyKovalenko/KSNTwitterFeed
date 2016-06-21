//
//  KSNErrorHandler.m
//  KSNErrorHandler
//
//  Created by Sergey Kovalenko on 11/21/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNErrorHandler.h"

const NSInteger KSNAllErrorsCode = NSIntegerMax;

FOUNDATION_STATIC_INLINE id TRASKSNErrorHandlerSafeCast(Class klass, id obj)
{
    return [obj isKindOfClass:klass] ? obj : nil;
}

static NSString *KSNErrorKey(NSString *errorDomain, NSInteger errorCode)
{
    return [NSString stringWithFormat:@"%@ - %li", errorDomain, (long)errorCode];
}

@interface TRAErrorHandlerInfo : NSObject <NSCopying>

- (instancetype)initWithErrorDomain:(NSString *)domain code:(NSInteger)code handler:(KSNErrorHandlerBlock)handlerBlock;

@property (nonatomic, copy, readonly) KSNErrorHandlerBlock handlerBlock;
@property (nonatomic, copy, readonly) NSString *errorDomain;
@property (nonatomic, assign, readonly) NSInteger errorCode;
@property (nonatomic, strong, readonly) NSString *key;

@end

@implementation TRAErrorHandlerInfo

- (instancetype)initWithErrorDomain:(NSString *)domain code:(NSInteger)code handler:(KSNErrorHandlerBlock)handlerBlock;
{
    self = [super init];
    if (self)
    {
        _errorDomain = [domain copy];
        _errorCode = code;
        _handlerBlock = [handlerBlock copy];
        _key = KSNErrorKey(self.errorDomain, self.errorCode);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [(TRAErrorHandlerInfo *) [[self class] alloc] initWithErrorDomain:self.errorDomain code:self.errorCode handler:self.handlerBlock];
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]])
    {
        return NO;
    }
    TRAErrorHandlerInfo *otherInfo = other;
    return [self.errorDomain isEqualToString:otherInfo.errorDomain] && self.errorCode == otherInfo.errorCode && self.handlerBlock == otherInfo.handlerBlock;
}

- (NSUInteger)hash
{
    return [self.key hash];
}

@end

@interface KSNErrorHandler ()

@property (nonatomic, strong) NSMutableDictionary *errorHandlers;
@end

@implementation KSNErrorHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.errorHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)addErrorHandlerWithBlock:(KSNErrorHandlerBlock)handler forErrorDomain:(NSString *)errorDomain errorCode:(NSInteger)errorCode
{
    TRAErrorHandlerInfo *info = [[TRAErrorHandlerInfo alloc] initWithErrorDomain:errorDomain code:errorCode handler:handler];
    NSMutableSet *handlers = self.errorHandlers[info.key];
    if (!handlers)
    {
        handlers = [NSMutableSet setWithObject:info];
        self.errorHandlers[info.key] = handlers;
    }
    else
    {
        [handlers addObject:info];
    }
    return info;
}

- (id)addErrorHandlerWithBlock:(KSNErrorHandlerBlock)handler forErrorDomain:(NSString *)errorDomain
{
    return [self addErrorHandlerWithBlock:handler forErrorDomain:errorDomain errorCode:KSNAllErrorsCode];
}

- (void)removeErrorHandler:(id)errorHandler
{
    TRAErrorHandlerInfo *info = TRASKSNErrorHandlerSafeCast([TRAErrorHandlerInfo class], errorHandler);
    NSMutableSet *handlers = self.errorHandlers[info.key];
    [handlers removeObject:info];
}

- (BOOL)handleError:(NSError *)error
{
    __block BOOL errorHandled = NO;
    NSMutableSet *handlers = self.errorHandlers[KSNErrorKey(error.domain, error.code)];
    NSMutableSet *domainHandlers = self.errorHandlers[KSNErrorKey(error.domain, KSNAllErrorsCode)];
    
    if (handlers.count > 0)
    {
        [handlers enumerateObjectsUsingBlock:^(TRAErrorHandlerInfo *info, BOOL *stop) {
            errorHandled |= info.handlerBlock(error);
        }];
    }
    
    if (!errorHandled && domainHandlers.count > 0)
    {
        [domainHandlers enumerateObjectsUsingBlock:^(TRAErrorHandlerInfo *info, BOOL *stop) {
            errorHandled |= info.handlerBlock(error);
        }];
    }
    
    if (!errorHandled && self.networkErrorHandler && KSNIsNetworkError(error))
    {
        errorHandled |= self.networkErrorHandler(error);
    }
    else if (!errorHandled && self.defaultErrorHandler)
    {
        errorHandled |= self.defaultErrorHandler(error);
    }
    return errorHandled;
}

@end
