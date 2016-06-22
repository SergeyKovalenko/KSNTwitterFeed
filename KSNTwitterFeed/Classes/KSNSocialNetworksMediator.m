//
//  KSNSocialNetworksMediator.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/22/16.
//
//

#import "KSNSocialNetworksMediator.h"
#import "KSNSocialAdapter.h"
#import "RACSignal.h"
#import "RACSignal+Operations.h"

@interface KSNSocialNetworksMediator ()

@property (nonatomic, readwrite) NSDictionary <NSString *, id <WKSocialAdapter>> *availableAdapters;
@end

@implementation KSNSocialNetworksMediator

- (instancetype)initWithSocialAdapters:(NSArray <id <WKSocialAdapter>> *)socialAdapters
{
    self = [super init];
    if (self)
    {
        NSMutableDictionary *adapters = [[NSMutableDictionary alloc] initWithCapacity:socialAdapters.count];
        for (id <WKSocialAdapter> adapter in socialAdapters)
        {
            adapters[adapter.socialAdapterName] = adapter;
        }
        _availableAdapters = [adapters copy];
    }

    return self;
}

- (RACSignal *)startUserSessionWithSocialAdapterName:(NSString *)socialAdapterName
{
    return [self.availableAdapters[socialAdapterName] startUserSession];
}

- (RACSignal *)endUserSessionWithSocialAdapterName:(NSString *)socialAdapterName
{
    return [self.availableAdapters[socialAdapterName] endUserSession];
}

- (RACSignal *)endUserSessions
{
    NSMutableArray *coldSignals = [[NSMutableArray alloc] initWithCapacity:self.availableAdapters.count];
    for (id <WKSocialAdapter> adapter in [self.availableAdapters allValues])
    {
        [coldSignals addObject:[RACSignal defer:^RACSignal * {
            return [adapter endUserSession];
        }]];
    }
    return [[RACSignal merge:coldSignals] ignoreValues];
}

- (id)userSessionWithSocialAdapterName:(NSString *)socialAdapterName
{
    return [self.availableAdapters[socialAdapterName] endUserSession];;
}

//- (RACSignal *)postMessage:(NSString *)message linkURL:(NSURL *)linkURL mediaURL:(NSURL *)mediaURL withSocialAdapterName:(NSString *)socialAdapterName
//{
//    return [self.availableAdapters[socialAdapterName] postMessage:message linkURL:linkURL mediaURL:linkURL];
//}

@end
