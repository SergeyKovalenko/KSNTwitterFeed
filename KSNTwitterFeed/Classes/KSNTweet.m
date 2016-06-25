//
// Created by Sergey Kovalenko on 6/24/16.
//

#import "KSNTweet.h"
#import "FEMMapping.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation KSNTweet

+ (FEMMapping *)tweetMapping
{
    static KSNTweet *Tweet;
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromDictionary:@{@keypath(Tweet, tweetID)     : @"id",
                                           @keypath(Tweet, text)        : @"text",
                                           @keypath(Tweet, createdDate) : @"created_at"}];
    return mapping;
}

@end