//
//  KSNNetworkAPI.m
//  9to5monk
//
//  Created by Sergey Kovalenko on 1/26/16.
//  Copyright © 2016 Windmill. All rights reserved.
//

#import "KSNNetworkAPI.h"
#import "KSNNetworkUtils.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

NSString *const KSNNetworkAPIErrorDomain = @"KSNNetworkAPIErrorDomain";

@interface KSNNetworkAPI ()

@property (nonatomic, strong) KSNNetworkClient *networkClient;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) RACScheduler *parsingScheduler;

@end

@implementation KSNNetworkAPI

+ (instancetype)api
{
    static KSNNetworkAPI *sharedAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAPI = [[self alloc] init];
    });
    return sharedAPI;
}

+ (NSError *)unexpectedServerResponseError
{
    return [NSError errorWithDomain:KSNNetworkAPIErrorDomain
                               code:KSNUnexpectedServerResponseNetworkAPIErrorCode
                           userInfo:@{NSLocalizedDescriptionKey : @"Unexpected Server Response"}];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        KSNNetworkAFNetworking *backingFramework = [[KSNNetworkAFNetworking alloc] init];
        _networkClient = [[KSNNetworkClient alloc] initWithBackingFramework:backingFramework];
        _baseURL = [NSURL URLWithString:[KSNNetworkAPIEndPoint activeEndPoint].baseURL];
        _parsingScheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.KSNNetworkAPI.response.parsingScheduler"];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serverBaseURLChanged:)
                                                     name:KSNNetworkAPIEndPointDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)serverBaseURLChanged:(NSNotification *)note
{
    KSNNetworkAPIEndPoint *endPoint = note.userInfo[KSNNetworkAPIEndPointKey];
    _baseURL = [NSURL URLWithString:endPoint.baseURL];
}

#pragma mark - Private Methods

- (NSString *)buildURLStringWithFormat:(NSString *)format, ...
{
    va_list args;
    NSString *URLString;
    if (format)
    {
        va_start(args, format);
        NSString *path = [[NSString alloc] initWithFormat:format arguments:args];
        URLString = [self buildURLStringWithPath:path];
        va_end(args);
    }
    return URLString;
}

- (NSString *)buildURLStringWithPath:(NSString *)path
{
    return [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
}

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request
{
    return [self model:model withNetworkRequest:request JSONMapBlock:nil];
}

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request JSONMapBlock:(id(^)(id))map
{
    return [self model:model withNetworkRequest:request JSONMapBlock:map reloadForEachSubscriber:NO];
}

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request JSONMapBlock:(id(^)(id))map reloadForEachSubscriber:(BOOL)reload
{
    NetworkLOG(@"Request %@ params %@", request.urlString, request.params);

    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers addEntriesFromDictionary:request.httpHeaders];
    request.httpHeaders = headers;

    request = [self.token signRequest:request];

    @weakify(self);
    RACSignal *data = [[[self rawDataWithNetworkRequest:request reloadForEachSubscriber:reload] flattenMap:^RACStream *(id value) {
        @strongify(self);
        return [self parseModel:model fromData:value responseMapBlock:map];
    }] deliverOn:[RACScheduler mainThreadScheduler]];

    [data setNameWithFormat:@"Request %@ params %@", request.urlString, request.params];
    return data;
}

- (RACSignal *)rawDataWithNetworkRequest:(KSNNetworkRequest *)request reloadForEachSubscriber:(BOOL)reloadForEachSubscriber //useStubs:(BOOL)stubs
{
    return [self.networkClient rawDataWithNetworkRequest:request reloadForEachSubscriber:reloadForEachSubscriber];
}

- (RACSignal *)parseModel:(id <KSNNetworkModel>)model fromData:(id)json responseMapBlock:(id(^)(id))mapBlock
{
    return [RACSignal startEagerlyWithScheduler:self.parsingScheduler block:^(id <RACSubscriber> subscriber) {

        NSError *error = nil;

        id <KSNNetworkModel> resultModel = [resultModel parseJSON:mapBlock ? mapBlock(json) : json error:&error];

        if (!resultModel)
        {
            [subscriber sendError:error ?: [KSNNetworkAPI unexpectedServerResponseError]];
        }
        else
        {
            [subscriber sendNext:resultModel];
            [subscriber sendCompleted];
        }
    }];
}

@end
