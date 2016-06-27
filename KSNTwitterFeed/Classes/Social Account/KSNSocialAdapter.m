//
// Created by Sergey Kovalenko on 6/22/16.
//

#import "KSNSocialAdapter.h"
#import <KSNUtils/KSNGlobalFunctions.h>


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
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

- (RACSignal *)startUserSession
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

- (RACSignal *)endUserSession
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

- (id)userSession
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

//- (RACSignal *)postMessage:(NSString *)message linkURL:(NSURL *)linkURL mediaURL:(NSURL *)mediaURL
//{
//    REQUIRE_OVERRIDE;
//    return nil;
//}

@end