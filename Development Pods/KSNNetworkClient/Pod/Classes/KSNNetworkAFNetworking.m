//
//  KSNNetworkAFNetworking.m
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNNetworkAFNetworking.h"
#import <AFNetworking/AFNetworking.h>

@interface KSNJSONRequestSerializer : AFJSONRequestSerializer
@end

@interface AFStreamingMultipartFormData : NSObject <AFMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;
@end

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

FOUNDATION_EXPORT NSArray * KSNQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * KSNNetworkQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * KSNQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in KSNQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * KSNQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return KSNNetworkQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray *KSNNetworkQueryStringPairsFromKeyAndValue(NSString *key, id value)
{
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]])
        {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue)
            {
                [mutableQueryStringComponents addObjectsFromArray:KSNNetworkQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]",
                                                                                                                                              key,
                                                                                                                                              nestedKey] : nestedKey), nestedValue)];
            }
        }
    }
    else if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = value;
        [array enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:KSNNetworkQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[%lu]",
                                                                                                                                   key,
                                                                                                                                   (unsigned long) idx], nestedValue)];
        }];
    }
    else if ([value isKindOfClass:[NSSet class]])
    {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[sortDescriptor]])
        {
            [mutableQueryStringComponents addObjectsFromArray:KSNNetworkQueryStringPairsFromKeyAndValue(key, obj)];
        }
    }
    else
    {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

@implementation KSNJSONRequestSerializer

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);

    NSMutableURLRequest *mutableRequest = [self requestWithMethod:method URLString:URLString parameters:nil error:error];

    __block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:mutableRequest
                                                                                               stringEncoding:NSUTF8StringEncoding];

    if (parameters)
    {
        for (AFQueryStringPair *pair in KSNNetworkQueryStringPairsFromKeyAndValue(nil, parameters))
        {
            NSData *data = nil;
            if ([pair.value isKindOfClass:[NSData class]])
            {
                data = pair.value;
            }
            else if ([pair.value isEqual:[NSNull null]])
            {
                data = [NSData data];
            }
            else
            {
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }

            if (data)
            {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }

    if (block)
    {
        block(formData);
    }

    return [formData requestByFinalizingMultipartFormData];
}
@end

@interface KSNNetworkAFNetworking ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation KSNNetworkAFNetworking


- (id)init
{
    self = [super init];
    if (self)
    {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _requestSerializer = [KSNJSONRequestSerializer serializer];
        _sessionManager.requestSerializer = _requestSerializer;
        AFJSONResponseSerializer  *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.readingOptions = NSJSONReadingMutableContainers;
        _responseSerializer = responseSerializer;
        _sessionManager.responseSerializer = responseSerializer;
    }
    return self;
}

- (void)setRequestSerializer:(AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer
{
    _requestSerializer = requestSerializer;
    _sessionManager.requestSerializer = requestSerializer;
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer<AFURLResponseSerialization> *)responseSerializer
{
    _responseSerializer = responseSerializer;
    _sessionManager.responseSerializer = responseSerializer;
}

- (void)registerHTTPHeaders:(NSDictionary *)headers
{
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
}

- (NSMutableURLRequest *)URLRequestWithRequest:(KSNNetworkRequest *)request error:(NSError *__autoreleasing *)error;
{
    NSMutableURLRequest *URLRequest = nil;
    if (request.multipartFormData.count)
    {
        URLRequest = [self multipartFormRequestWithRequest:request error:error];
    }
    else
    {
        URLRequest = [self.requestSerializer requestWithMethod:request.httpMethod URLString:request.urlString parameters:request.params error:error];
    }
    
    [request.httpHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *header, NSString *value, BOOL *stop) {
        [URLRequest setValue:value forHTTPHeaderField:header];
    }];
    return URLRequest;
}

- (NSMutableURLRequest *)multipartFormRequestWithRequest:(KSNNetworkRequest *)request error:(NSError *__autoreleasing *)error
{
    __block BOOL isMultipartFormDataConstructed = YES;
    void (^formConstructingBlock)(id <AFMultipartFormData>) = ^(id <AFMultipartFormData> formData) {
        
        for (AFQueryStringPair *pair in KSNNetworkQueryStringPairsFromKeyAndValue(nil, request.multipartFormData))
        {
            NSData *data = nil;
            NSURL *fileURL = nil;
            
            if ([pair.value isKindOfClass:[NSData class]])
            {
                data = pair.value;
            }
            else if ([pair.value isEqual:[NSNull null]])
            {
                data = [NSData data];
            }
            else if ([pair.value isKindOfClass:[NSURL class]])
            {
                fileURL = pair.value;
            }
            else if ([pair.value isKindOfClass:[UIImage class]])
            {
                [formData appendPartWithFileData:UIImageJPEGRepresentation((UIImage *) pair.value, 1)
                                            name:pair.field
                                        fileName:@"image"
                                        mimeType:@"image/jpeg"];
            }
            else
            {
                data = [[pair.value description] dataUsingEncoding:self.requestSerializer.stringEncoding];
            }
            
            if (data)
            {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
            
            if (fileURL)
            {
                isMultipartFormDataConstructed = [formData appendPartWithFileURL:fileURL name:pair.field error:error];
                if (!isMultipartFormDataConstructed)
                {
                    break;
                }
            }
        }
    };
    NSMutableURLRequest *req = [self.requestSerializer multipartFormRequestWithMethod:request.httpMethod
                                                                            URLString:request.urlString
                                                                           parameters:request.params
                                                            constructingBodyWithBlock:formConstructingBlock
                                                                                error:error];
    return isMultipartFormDataConstructed ? req : nil;
}

- (id <KSNNetworkOperation>)operationForDispatchedRequest:(KSNNetworkRequest *)request
                                            successBlock:(KSNNetworkResponseBlock)successBlock
                                            failureBlock:(KSNNetworkErrorBlock)failureBlock
{
    NSError *error = nil;
    NSMutableURLRequest *req = [self URLRequestWithRequest:request error:&error];
    __block id task = nil;
    
    if (req)
    {
        void (^completionHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *__unused response, id responseObject, NSError *taskError) {
            if (taskError)
            {
                if (failureBlock)
                {
                    failureBlock(task, responseObject, taskError);
                }
            }
            else
            {
                if (successBlock)
                {
                    successBlock(task, responseObject);
                }
            }
        };
        
        if (request.multipartFormData.count)
        {
            task = [self.sessionManager uploadTaskWithStreamedRequest:req progress:nil completionHandler:completionHandler];
        }
        else
        {
            task = [self.sessionManager dataTaskWithRequest:req completionHandler:completionHandler];
        }
    }
    else
    {
        if (failureBlock)
        {
            failureBlock(nil, nil, error);
        }
    }
    
    [task resume];
    return task;
}

@end
