//
// Created by Sergey Kovalenko on 6/24/16.
//

#import "KSNTweet.h"
#import "FEMMapping.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation KSNTweet

@dynamic tweetID;
@dynamic text;
@dynamic createdDate;

+ (FEMMapping *)tweetMapping
{
    static KSNTweet *Tweet;
    FEMMapping *mapping = [[FEMMapping alloc] initWithEntityName:NSStringFromClass(self)];
    mapping.primaryKey = @keypath(Tweet, tweetID);
    [mapping addAttributesFromDictionary:@{@keypath(Tweet, tweetID)     : @"id",
                                           @keypath(Tweet, text)        : @"text",
                                           @keypath(Tweet, createdDate) : @"created_at"}];
    return mapping;
}

+ (NSManagedObjectModel *)managedObjectModel
{
    NSBundle *assetsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self] pathForResource:@"KSNTwitterFeedBundle" ofType:@"bundle"]];
    return [NSManagedObjectModel mergedModelFromBundles:@[assetsBundle]];
}

@end