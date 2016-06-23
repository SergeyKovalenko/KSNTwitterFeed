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

@import Social;
@import Accounts;

@interface KSNTwitterAPI ()

@property (nonatomic, strong) KSNTwitterSocialAdapter *socialAdapter;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) RACScheduler *parsingScheduler;
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

- (RACSignal *)performRequestWithHandler:(SLRequest *)request deserializer:(id <KSNTwitterResponseDeserializer>)deserializer reloadForEachSubscriber:(BOOL)reloadForEachSubscriber
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
                    [[self parseModel:deserializer fromData:responseData] subscribe:subscriber];
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

- (RACSignal *)parseModel:(id <KSNTwitterResponseDeserializer>)deserializer fromData:(NSData *)responseData
{
    return [RACSignal startEagerlyWithScheduler:self.parsingScheduler block:^(id <RACSubscriber> subscriber) {

        id responseObject = nil;
        NSError *serializationError = nil;
        // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
        // See https://github.com/rails/rails/issues/1742
        BOOL isSpace = [responseData isEqualToData:[NSData dataWithBytes:" " length:1]];
        if (responseData.length > 0 && !isSpace)
        {
            responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&serializationError];
            if (responseObject)
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
            else
            {
                [subscriber sendError:serializationError];
            }
        }
        else
        {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        }
    }];
}

- (RACSignal *)userTimelineWithDeserializer:(id <KSNTwitterResponseDeserializer>)deserializer
{
    ACAccount *account = self.socialAdapter.activeAccount;
    if (account)
    {
        NSURL *URL = [self buildURLWithPath:@"statuses/user_timeline.json"];
        SLRequest *request = [self requestWithMethod:SLRequestMethodGET URL:URL parameters:nil];
        return [self performRequestWithHandler:request deserializer:nil reloadForEachSubscriber:NO];
    }
    else
    {
        return [RACSignal error:nil];
    }
}

@end
