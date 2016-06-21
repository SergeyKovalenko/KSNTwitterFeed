//
// Created by Sergey Kovalenko on 2/5/16.
//

#import "KSNNetworkAPIStub.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <objc/runtime.h>

@interface NSInvocation (NTFAdditions)

- (NSArray *)ntf_arguments;
- (id)ntf_argumentAtIndex:(NSUInteger)index;
@end

@implementation NSInvocation (NTFAdditions)

- (id)ntf_argumentAtIndex:(NSUInteger)index
{
#define WRAP_AND_RETURN(type) \
    do { \
        type val = 0; \
        [self getArgument:&val atIndex:(NSInteger)index]; \
        return @(val); \
    } while (0)

    const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
    // Skip const type qualifier.
    if (argType[0] == 'r')
    {
        argType++;
    }

    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0)
    {
        __autoreleasing id returnObj;
        [self getArgument:&returnObj atIndex:(NSInteger) index];
        return returnObj;
    }
    else if (strcmp(argType, @encode(char)) == 0)
    {
        WRAP_AND_RETURN(char);
    }
    else if (strcmp(argType, @encode(int)) == 0)
    {
        WRAP_AND_RETURN(int);
    }
    else if (strcmp(argType, @encode(short)) == 0)
    {
        WRAP_AND_RETURN(short);
    }
    else if (strcmp(argType, @encode(long)) == 0)
    {
        WRAP_AND_RETURN(long);
    }
    else if (strcmp(argType, @encode(long long)) == 0)
    {
        WRAP_AND_RETURN(long long);
    }
    else if (strcmp(argType, @encode(unsigned char)) == 0)
    {
        WRAP_AND_RETURN(unsigned char);
    }
    else if (strcmp(argType, @encode(unsigned int)) == 0)
    {
        WRAP_AND_RETURN(unsigned int);
    }
    else if (strcmp(argType, @encode(unsigned short)) == 0)
    {
        WRAP_AND_RETURN(unsigned short);
    }
    else if (strcmp(argType, @encode(unsigned long)) == 0)
    {
        WRAP_AND_RETURN(unsigned long);
    }
    else if (strcmp(argType, @encode(unsigned long long)) == 0)
    {
        WRAP_AND_RETURN(unsigned long long);
    }
    else if (strcmp(argType, @encode(float)) == 0)
    {
        WRAP_AND_RETURN(float);
    }
    else if (strcmp(argType, @encode(double)) == 0)
    {
        WRAP_AND_RETURN(double);
    }
    else if (strcmp(argType, @encode(BOOL)) == 0)
    {
        WRAP_AND_RETURN(BOOL);
    }
    else if (strcmp(argType, @encode(char *)) == 0)
    {
        WRAP_AND_RETURN(const char *);
    }
    else if (strcmp(argType, @encode(void (^)(void))) == 0)
    {
        __unsafe_unretained id block = nil;
        [self getArgument:&block atIndex:(NSInteger) index];
        return [block copy];
    }
    else
    {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);

        unsigned char valueBytes[valueSize];
        [self getArgument:valueBytes atIndex:(NSInteger) index];

        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }

    return nil;

#undef WRAP_AND_RETURN
}

- (NSArray *)ntf_arguments
{
    NSUInteger numberOfArguments = self.methodSignature.numberOfArguments;
    NSMutableArray *argumentsArray = [NSMutableArray arrayWithCapacity:numberOfArguments - 2];
    for (NSUInteger index = 2; index < numberOfArguments; index++)
    {
        [argumentsArray addObject:[self ntf_argumentAtIndex:index] ?: [NSNull null]];
    }

    return argumentsArray;
}

@end

@implementation KSNNetworkAPIStub

static BOOL NTFSignalReturningMethodSignature(NSMethodSignature *signature)
{
    return strcmp(signature.methodReturnType, @encode(RACSignal *)) == 0;
}

- (instancetype)init
{
    self.responseDelay = 3.0;
    return self;
}

+ (instancetype)errorStubWithRealAPI:(id)api error:(NSError *)error;
{
    KSNNetworkAPIStub *stub = [[self alloc] init];
    stub.api = api;
    stub.error = error ?: [self unexpectedServerResponseError];
    return stub;
}

+ (instancetype)stubWithRealAPI:(id)api selectorToResponseObjectMap:(id (^)(SEL, NSArray *))mapBlock
{
    KSNNetworkAPIStub *stub = [[self alloc] init];
    stub.api = api;
    if (mapBlock)
    {
        stub.mapBlock = mapBlock;
    }
    else
    {
        stub.error = [self unexpectedServerResponseError];
    }

    return stub;
}

+ (BOOL)respondsToSelector:(SEL)aSelector
{
    return [[self class] respondsToSelector:aSelector];
}

+ (NSError *)unexpectedServerResponseError
{
    return [NSError errorWithDomain:KSNNetworkAPIErrorDomain
                               code:KSNUnexpectedServerResponseNetworkAPIErrorCode
                           userInfo:@{NSLocalizedDescriptionKey : @"Unexpected Server Response"}];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *signature = [self.api methodSignatureForSelector:sel];
//    return NTFSignalReturningMethodSignature(signature) ? [self stubMethodSignature] : signature;
    return signature;
}

- (NSMethodSignature *)stubMethodSignature
{
    Method method = class_getInstanceMethod([self class], @selector(stubAPIMethodForSelector:parameters:));
    const char *types = method_getTypeEncoding(method);
    return [NSMethodSignature signatureWithObjCTypes:types];
}

- (RACSignal *)stubAPIMethodForSelector:(SEL)selector parameters:(NSArray *)params
{
    RACSignal *racSignal = self.mapBlock ? [RACSignal return:self.mapBlock(selector, params)] : [RACSignal error:self.error];
    return [[[RACSignal empty] delay:3] concat:racSignal];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (NTFSignalReturningMethodSignature(invocation.methodSignature))
    {
        SEL selector = invocation.selector;
        NSArray *args = [invocation ntf_arguments];
        RACSignal *signal = [self stubAPIMethodForSelector:selector parameters:args];
        [invocation setReturnValue:&signal];
    }
    else
    {
        [invocation invokeWithTarget:self.api];
    }
}

+ (Class)class
{
    return [KSNNetworkAPI class];
}

@end

@implementation KSNNetworkAPI (Stubbing)

- (instancetype)stub;
{
    return (id) [KSNNetworkAPIStub stubWithRealAPI:self selectorToResponseObjectMap:^id(SEL sel, NSArray *args) {
        NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:NSStringFromSelector(sel) ofType:@"json"];
        if (path)
        {
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
            id JSON = nil;
            if (data)
            {
                JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }

            return JSON;
        }
        else
        {
            if ([UIApplication sharedApplication].delegate.window)
            {
                [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Add file %@.json", [NSStringFromSelector(sel) lastPathComponent]]
                                            message:nil
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
        }

        return nil;
    }];
}

- (instancetype)stubWithError:(NSError *)error
{
    return (id) [KSNNetworkAPIStub errorStubWithRealAPI:self error:[KSNNetworkAPIStub unexpectedServerResponseError]];
}

@end

