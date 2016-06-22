//
// Created by Sergey Kovalenko on 6/22/16.
//

#import "KSNSocialAdapter.h"

#define REQUIRE_OVERRIDE NSAssert(NO, @"Override %2$@ in %1$@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd))

@interface KSNSocialAdapter ()

@property (nonatomic, copy, readwrite) NSString *socialAdapterName;

@end

@implementation KSNSocialAdapter

- (instancetype)initWithSocialAdapterName:(NSString *)socialAdapterName
{
    self = [super init];
    if (self)
    {
        _socialAdapterName = [socialAdapterName copy];
    }

    return self;
}

#pragma mark - WKSocialAdapter protocol implementation

- (NSString *)socialAdapterName
{
    REQUIRE_OVERRIDE;
    return nil;
}

- (RACSignal *)startUserSession
{
    REQUIRE_OVERRIDE;
    return nil;
}

- (RACSignal *)endUserSession
{
    REQUIRE_OVERRIDE;
    return nil;
}

- (id)userSession
{
    REQUIRE_OVERRIDE;
    return nil;
}

//- (RACSignal *)postMessage:(NSString *)message linkURL:(NSURL *)linkURL mediaURL:(NSURL *)mediaURL
//{
//    REQUIRE_OVERRIDE;
//    return nil;
//}

@end