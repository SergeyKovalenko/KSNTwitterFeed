//
//  KSNNetworkModelDeserializer.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//

#import <FastEasyMapping/FEMDeserializer.h>
#import <KSNUtils/KSNGlobalFunctions.h>

#import "KSNNetworkModelDeserializer.h"
#import "FEMManagedObjectStore.h"

@import CoreData;

@interface KSNNetworkModelDeserializer ()

@property (nonatomic, strong, readwrite) FEMDeserializer *deserializer;
@property (nonatomic, strong, readwrite) FEMMapping *mapping;
@property (nonatomic, copy) id (^normalizationBlock)(id, NSError **);

@end

@interface KSNNetworNativeModelDeserializer : KSNNetworkModelDeserializer

@end

@implementation KSNNetworNativeModelDeserializer

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
                             context:(__unused NSManagedObjectContext *)context
              JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    NSParameterAssert(mapping);
    self = [super init];
    if (self)
    {
        self.deserializer = [[FEMDeserializer alloc] init];
        self.mapping = mapping;
        self.normalizationBlock = normalizationBlock;
    }
    return self;
}

- (id)objectFromRepresentation:(id)representation
{
    if (KSNSafeCast([NSArray class], representation))
    {
        return [self.deserializer collectionFromRepresentation:representation mapping:self.mapping];
    }
    else if (KSNSafeCast([NSDictionary class], representation))
    {
        return [self.deserializer objectFromRepresentation:representation mapping:self.mapping];
    }
    else
    {
        NSAssert(NO, @"Unsupported representation class %@ - %@", NSStringFromClass([representation class]), representation);
        return nil;
    }
}

@end

@interface KSNNetworCoreDataModelDeserializer : KSNNetworkModelDeserializer

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation KSNNetworCoreDataModelDeserializer

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
                             context:(NSManagedObjectContext *)context
              JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    NSParameterAssert(mapping);
    NSParameterAssert(context);
    
    self = [super init];
    if (self)
    {
        self.context = context;
        FEMManagedObjectStore *store =[[FEMManagedObjectStore alloc] initWithContext:context];
//        store.saveContextOnCommit = YES;
        self.deserializer = [[FEMDeserializer alloc] initWithStore:store];
        self.mapping = mapping;
        self.normalizationBlock = normalizationBlock;
    }
    return self;
}

- (id)objectFromRepresentation:(id)representation
{
    __block id result;
    [self.context performBlockAndWait:^{
        if (KSNSafeCast([NSArray class], representation))
        {
            result = [self.deserializer collectionFromRepresentation:representation mapping:self.mapping];
        }
        else if (KSNSafeCast([NSDictionary class], representation))
        {
            result = [self.deserializer objectFromRepresentation:representation mapping:self.mapping];
        }
        else
        {
            NSAssert(NO, @"Unsupported representation class %@ - %@", NSStringFromClass([representation class]), representation);
        }
    }];
    return result;
}

@end

@implementation KSNNetworkModelDeserializer

- (instancetype)init
{
    if (self.class == KSNNetworkModelDeserializer.class)
    {
        return [self initWithModelMapping:nil];
    }
    else
    {
        return [super init];
    }
}

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
{
    return [self initWithModelMapping:mapping JSONNormalizationBlock:nil];
}

- (instancetype)initWithModelMapping:(FEMMapping *)mapping JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    return [self initWithModelMapping:mapping context:nil JSONNormalizationBlock:normalizationBlock];
}

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
                             context:(NSManagedObjectContext *)context
              JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    NSParameterAssert(mapping);
    if (context)
    {
        return [[KSNNetworCoreDataModelDeserializer alloc] initWithModelMapping:mapping
                                                                        context:context
                                                         JSONNormalizationBlock:normalizationBlock];
    }
    else
    {
        return [[KSNNetworkModelDeserializer alloc] initWithModelMapping:mapping
                                                                 context:context
                                                  JSONNormalizationBlock:normalizationBlock];
    }
}

- (id)parseJSON:(id)json error:(NSError **)pError
{
    id representation = nil;
    if (self.normalizationBlock)
    {
        representation = self.normalizationBlock(json, pError);
    }
    else
    {
        representation = json;
    }
    
    return representation ? [self objectFromRepresentation:representation] : nil;
}

- (id)objectFromRepresentation:(id)representation
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

@end