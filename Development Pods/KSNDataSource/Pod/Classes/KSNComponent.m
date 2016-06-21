//
//  KSNComponent.m
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNComponent.h"
#import <KSNUtils/KSNGlobalFunctions.h>
#import <KSNUtils/KSNDebug.h>

@interface KSNComponent ()

@property (nonatomic, strong) NSMutableArray *components;
@property (nonatomic, strong, readwrite) NSArray *flattenComponents;
@property (nonatomic, weak, readwrite) id <KSNComponentTraits> parent;
@end

@implementation KSNComponent

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _components = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithValue:(id)value
{
    self = [self init];
    if (self)
    {
        self.value = value;
    }
    return self;
}

+ (NSArray *)componentsForValues:(id <NSFastEnumeration, NSObject>)values adjustingBlock:(void (^)(id <KSNComponentTraits> component))adjustingBlock
{
    return [self componentsForValues:values factoryBlock:^id <KSNComponentTraits>(id value) {
        id <KSNComponentTraits> component = [[self alloc] initWithValue:value];

        if (adjustingBlock)
        {
            adjustingBlock(component);
        }

        return component;
    }];
}

+ (NSArray *)componentsForValues:(id <NSFastEnumeration, NSObject>)values factoryBlock:(id <KSNComponentTraits>(^)(id value))factoryBlock
{
    if ([values conformsToProtocol:@protocol(NSFastEnumeration)] && factoryBlock)
    {
        NSMutableArray *components = [NSMutableArray array];
        for (id value in values)
        {
            __block id <KSNComponentTraits> rootComponent = factoryBlock(value);

            for (id <KSNComponentTraits> component in [self componentsForValues:value factoryBlock:factoryBlock])
            {
                [rootComponent addComponent:component];
            }

            [components addObject:rootComponent];
        }
        return components;
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)count
{
    NSUInteger count = 1;
    for (KSNComponent *childComponent in self.components)
    {
        count += childComponent.count;
    }
    return count;
}

- (NSArray *)flattenComponents
{
    if (!_flattenComponents)
    {
        _flattenComponents = [[self buildFlattenComponents] copy];
    }
    return _flattenComponents;
}

- (NSArray *)childs
{
    // Return mutable array here to improve performance only
    return self.components;
}

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray arrayWithObject:self];
    for (KSNComponent *childComponent in self.components)
    {
        [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
    }
    return flattenComponents;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    if (state->state < self.flattenComponents.count)
    {
        NSUInteger count = MIN(self.flattenComponents.count - state->state, len);
        [self.flattenComponents getObjects:buffer range:NSMakeRange(state->state, count)];
        state->itemsPtr = buffer;
        void **mutationsPtr = (void *) &_flattenComponents;
        state->mutationsPtr = (unsigned long *) mutationsPtr;
        state->state += count;
        return count;
    }
    else
    {
        return 0;
    }
}

- (void)addComponent:(id <KSNComponentTraits>)component
{
    KSNASSERT([component conformsToProtocol:@protocol(KSNComponentTraits)]);
    [self clearCache];
    KSNComponent *child = KSNSafeCast([KSNComponent class], component);
    child.parent = self;
    [self.components addObject:component];
}

- (BOOL)containsComponent:(id <KSNComponentTraits>)component
{
    BOOL contains = [self.components containsObject:component];
    if (!contains)
    {
        for (id <KSNComponentTraits> child in self.components)
        {
            if ((contains = [child containsComponent:component]))
            {
                break;
            }
        }
    }
    return contains;
}

- (void)clearCache
{
    _flattenComponents = nil;
    KSNComponent *parent = KSNSafeCast([KSNComponent class], self.parent);
    [parent clearCache];
}

- (void)removeComponent:(id <KSNComponentTraits>)component
{
    NSUInteger index = [self.components indexOfObject:component];

    if (index == NSNotFound)
    {
        for (KSNComponent *child in self.components)
        {
            [child removeComponent:component];
        }
    }
    else
    {
        KSNComponent *child = KSNSafeCast([KSNComponent class], component);
        child.parent = nil;
        [self.components removeObjectAtIndex:index];
        [self clearCache];
    }
}

- (void)removeAllComponents
{
    for (id <KSNComponentTraits> component in self.components)
    {
        KSNComponent *child = KSNSafeCast([KSNComponent class], component);
        child.parent = nil;
    }
    [self.components removeAllObjects];
    [self clearCache];
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]])
    {
        return NO;
    }
    KSNComponent *otherComponent = other;
    return [self.value isEqual:otherComponent.value];
}

- (NSUInteger)hash
{
    return [self.value hash];
}

@end
