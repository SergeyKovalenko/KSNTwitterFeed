//
//  KSNTwitterAPI.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//


#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNTwitterAPI.h"
#import "KSNTwitterSocialAdapter.h"
#import "AFNetworking.h"

@import Social;
@import Accounts;

@interface KSNTwitterAPI ()

@property (nonatomic, strong) KSNTwitterSocialAdapter *socialAdapter;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) RACScheduler *parsingScheduler;
@property (nonatomic, strong) AFJSONResponseSerializer *responceSerializer;
@end

@implementation KSNTwitterAPI

- (instancetype)initWithSocialAdapter:(KSNTwitterSocialAdapter *)socialAdapter
{
    self = [super init];
    if (self)
    {
        _socialAdapter = socialAdapter;
        _baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
        _parsingScheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.KSNTwitterAPI.response.parsingScheduler"];
        _responceSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:0];
    }

    return self;
}

- (NSURL *)buildURLWithFormat:(NSString *)format, ...
{
    va_list args;
    NSURL *URLString;
    if (format)
    {
        va_start(args, format);
        NSString *path = [[NSString alloc] initWithFormat:format arguments:args];
        URLString = [self buildURLWithPath:path];
        va_end(args);
    }
    return URLString;
}

- (NSURL *)buildURLWithPath:(NSString *)path
{
    return [NSURL URLWithString:path relativeToURL:self.baseURL];
}

- (SLRequest *)requestWithMethod:(SLRequestMethod)requestMethod URL:(NSURL *)url parameters:(NSDictionary *)parameters;
{
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:requestMethod URL:url parameters:parameters];
    request.account = self.socialAdapter.activeAccount;
    return request;
}

- (RACSignal *)performRequestWithHandler:(SLRequest *)request
                            deserializer:(id <KSNTwitterResponseDeserializer>)deserializer
                 reloadForEachSubscriber:(BOOL)reloadForEachSubscriber
{
    @weakify(self);
    RACSignal *networkRequest = [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {

        RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
            //           Nothing to cancel :(. It would be better to create NSURLSessionDataTask but let's leave it for a real-life app
        }];
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (!disposable.isDisposed)
            {
                if (error)
                {
                    [subscriber sendError:error];
                }
                else
                {
                    @strongify(self);
                    [[self parseModel:deserializer urlResponse:urlResponse fromData:responseData] subscribe:subscriber];
                }
            }
        }];
        return disposable;
    }];

    if (!reloadForEachSubscriber)
    {
        RACMulticastConnection *connection = [networkRequest multicast:[RACReplaySubject subject]];
        return [[connection autoconnect] deliverOnMainThread];
    }
    else
    {
        return [networkRequest deliverOnMainThread];
    }
}

- (RACSignal *)parseModel:(id <KSNTwitterResponseDeserializer>)deserializer
              urlResponse:(NSHTTPURLResponse *)urlResponse
                 fromData:(NSData *)responseData
{
    @weakify(self);
    return [RACSignal startEagerlyWithScheduler:self.parsingScheduler block:^(id <RACSubscriber> subscriber) {
        
        NSError *serializationError = nil;
        id responseObject = [self.responceSerializer responseObjectForResponse:urlResponse data:responseData error:&serializationError];
        if (serializationError)
        {
            [subscriber sendError:serializationError];
        }
        else
        {
            id result = [deserializer parseJSON:responseObject error:&serializationError];
            if (result)
            {
                [subscriber sendNext:result];
                [subscriber sendCompleted];
            }
            else
            {
                [subscriber sendError:serializationError];
            }
            
        }
    }];
}

@end

@implementation KSNTwitterAPI (UserTimeLine)

- (RACSignal *)userTimeLineWithDeserializer:(id <KSNTwitterResponseDeserializer>)deserializer
                               sinceTweetID:(NSNumber *)sinceID
                                 maxTweetID:(NSNumber *)maxTweetID
                                      count:(NSNumber *)count
{
    NSURL *URL = [self buildURLWithPath:@"statuses/user_timeline.json"];
    SLRequest *request = [self requestWithMethod:SLRequestMethodGET
                                             URL:URL
                                      parameters:@{@"since_id" : sinceID ?: [NSNull null],
                                                   @"max_id"   : maxTweetID ?: [NSNull null],
                                                   @"count"    : count ?: [NSNull null]}];

    return [self performRequestWithHandler:request deserializer:deserializer reloadForEachSubscriber:NO];
}
@end
