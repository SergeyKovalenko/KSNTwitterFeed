//
//  KSNCollapsibleComponent.m
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNCollapsibleComponent.h"
#import <KSNUtils/KSNGlobalFunctions.h>
#import <KSNUtils/NSArray+KSNFunctionalAdditions.h>

static void *WKCollapsibleComponentObjectCollapsedKeyPathContext = &WKCollapsibleComponentObjectCollapsedKeyPathContext;

@interface KSNComponent ()

@property (nonatomic, strong) NSMutableArray *components;
- (void)clearCache;

@end

@interface KSNCollapsibleComponent ()

@property (nonatomic, strong) NSMutableSet *observingComponents;

- (void)addObserverForComponent:(NSObject <WKCollapsibleComponentTraits> *)collapsibleComponent;
- (void)removeObserverFromComponent:(NSObject <WKCollapsibleComponentTraits> *)collapsibleComponent;

@end

@implementation KSNCollapsibleComponent

@synthesize collapsed = _collapsed;

#pragma mark - Initialization

- (instancetype)initWithValue:(id)value
{
    self = [super initWithValue:value];
    if (self)
    {
        self.collapsed = YES;
        self.observingComponents = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self.components enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSObject <WKCollapsibleComponentTraits> *collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), obj);
        if (collapsibleComponent)
        {
            [self removeObserverFromComponent:collapsibleComponent];
        }
    }];
}

#pragma mark - Properties

- (void)setCollapsed:(BOOL)collapsed
{
    if (collapsed != _collapsed)
    {
        _collapsed = collapsed;
        [self clearCache];
    }
}

- (NSArray *)expandedComponents
{
    NSMutableArray *expandedComponents = [[NSMutableArray alloc] init];

    if (!self.isCollapsed)
    {
        [expandedComponents addObject:self];
    }

    [self.components enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        id <WKCollapsibleComponentTraits> collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), obj);
        if (collapsibleComponent)
        {
            [expandedComponents addObjectsFromArray:[collapsibleComponent expandedComponents]];
        }
    }];

    return [expandedComponents copy];
}

- (NSUInteger)count
{
    NSUInteger count = 1;
    if (!self.isCollapsed)
    {
        for (KSNCollapsibleComponent *childComponent in self.components)
        {
            count += childComponent.count;
        }
    }
    return count;
}

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray arrayWithObject:self];
    if (!self.isCollapsed)
    {
        for (KSNComponent *childComponent in self.components)
        {
            [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
        }
    }
    return flattenComponents;
}

#pragma mark - WKComponentTraits

- (void)addComponent:(id <KSNComponentTraits>)component
{
    [super addComponent:component];

    NSObject <WKCollapsibleComponentTraits> *collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), component);
    if (collapsibleComponent)
    {
        [self addObserverForComponent:collapsibleComponent];
    }
}

- (void)removeComponent:(id <KSNComponentTraits>)component
{
    [super removeComponent:component];

    NSObject <WKCollapsibleComponentTraits> *collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), component);
    if (collapsibleComponent)
    {
        [self removeObserverFromComponent:collapsibleComponent];
    }
}

- (void)removeAllComponents
{
    [self.components enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSObject <WKCollapsibleComponentTraits> *collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), obj);
        if (collapsibleComponent)
        {
            [self removeObserverFromComponent:collapsibleComponent];
        }
    }];

    [super removeAllComponents];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if (context == WKCollapsibleComponentObjectCollapsedKeyPathContext)
    {
        if ([keyPath isEqualToString:@"collapsed"])
        {
            id <WKCollapsibleComponentTraits> collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), object);
            if (collapsibleComponent)
            {
                if ([self.components containsObject:collapsibleComponent])
                {
                    [self p_childWasChangeCollapsedState:collapsibleComponent];
                }
            }
        }
    }
}

- (void)p_childWasChangeCollapsedState:(id <WKCollapsibleComponentTraits>)collapsibleComponent
{
    [self clearCache];
}

#pragma mark - Private

- (void)addObserverForComponent:(NSObject <WKCollapsibleComponentTraits> *)collapsibleComponent
{
    if (![self.observingComponents containsObject:collapsibleComponent])
    {
        [collapsibleComponent addObserver:self forKeyPath:@"collapsed"
        options:
        NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
        context:
        WKCollapsibleComponentObjectCollapsedKeyPathContext];
        [self.observingComponents addObject:collapsibleComponent];
    }
}

- (void)removeObserverFromComponent:(NSObject <WKCollapsibleComponentTraits> *)collapsibleComponent
{
    if ([self.observingComponents containsObject:collapsibleComponent])
    {
        [collapsibleComponent removeObserver:self forKeyPath:@"collapsed"
        context:
        WKCollapsibleComponentObjectCollapsedKeyPathContext];
        [self.observingComponents removeObject:collapsibleComponent];
    }
}

@end

@implementation WKExcludeSelfComponent

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray array];
    for (KSNComponent *childComponent in self.components)
    {
        [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
    }
    return flattenComponents;
}

@end

@implementation WKSingleSelectionCollapsibleComponent

- (void)setCollapsed:(BOOL)collapsed
{
    [super setCollapsed:collapsed];

    if (collapsed)
    {
        [self.components enumerateObjectsUsingBlock:^(id <WKCollapsibleComponentTraits> collapsibleComponent, NSUInteger idx, BOOL *stop) {
            [self removeObserverFromComponent:collapsibleComponent];

            collapsibleComponent.collapsed = collapsed;

            [self addObserverForComponent:collapsibleComponent];
        }];
    }
}

- (void)p_childWasChangeCollapsedState:(id <WKCollapsibleComponentTraits>)collapsibleComponent
{
    if (![collapsibleComponent isCollapsed])
    {
        NSArray *expandedComponents = [self.childs ksn_filter:^BOOL(id object) {
            id <WKCollapsibleComponentTraits> p_collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), object);
            if (p_collapsibleComponent && p_collapsibleComponent != collapsibleComponent)
            {
                return ![p_collapsibleComponent isCollapsed];
            }
            else
            {
                return NO;
            }
        }];

        [expandedComponents enumerateObjectsUsingBlock:^(NSObject <WKCollapsibleComponentTraits> *p_collapsibleComponent, NSUInteger idx, BOOL *_Nonnull stop) {

            [self removeObserverFromComponent:p_collapsibleComponent];

            p_collapsibleComponent.collapsed = YES;

            [self addObserverForComponent:p_collapsibleComponent];
        }];
    }

    __block BOOL collapsed = YES;
    [self.childs enumerateObjectsUsingBlock:^(id <WKCollapsibleComponentTraits> collapsibleComponent, NSUInteger idx, BOOL *stop) {
        collapsed &= [collapsibleComponent isCollapsed];
    }];
    if (!collapsed || ![[self parent] parent])
    {
        self.collapsed = collapsed;
    }

    [super p_childWasChangeCollapsedState:collapsibleComponent];
}

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray arrayWithObject:self];

    for (KSNCollapsibleComponent *childComponent in self.components)
    {
        if (![childComponent isCollapsed] && childComponent.childs.count > 0)
        {
            [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
        }
    }

    return flattenComponents;
}

@end

@implementation WKMultipleSelectionCollapsibleComponent

- (void)setCollapsed:(BOOL)collapsed
{
    [super setCollapsed:collapsed];

    if (collapsed)
    {
        [self.components enumerateObjectsUsingBlock:^(id <WKCollapsibleComponentTraits> collapsibleComponent, NSUInteger idx, BOOL *stop) {
            [self removeObserverFromComponent:collapsibleComponent];

            collapsibleComponent.collapsed = collapsed;

            [self addObserverForComponent:collapsibleComponent];
        }];
    }
}

- (void)p_childWasChangeCollapsedState:(id <WKCollapsibleComponentTraits>)collapsibleComponent
{
    __block BOOL collapsed = YES;
    [self.components enumerateObjectsUsingBlock:^(id <WKCollapsibleComponentTraits> collapsibleComponent, NSUInteger idx, BOOL *stop) {
        collapsed &= [collapsibleComponent isCollapsed];
    }];
    if (!collapsed || ![[self parent] parent])
    {
        self.collapsed = collapsed;
    }

    [super p_childWasChangeCollapsedState:collapsibleComponent];
}

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray arrayWithObject:self];

    for (KSNCollapsibleComponent *childComponent in self.components)
    {
        if (![childComponent isCollapsed] && childComponent.components.count > 0)
        {
            [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
        }
    }

    return flattenComponents;
}

@end

@implementation WKSortOrderCollapsibleComponent

- (void)p_childWasChangeCollapsedState:(NSObject <WKCollapsibleComponentTraits> *)collapsibleComponent
{
    if (![collapsibleComponent isCollapsed])
    {
        NSArray *expandedComponents = [self.childs ksn_filter:^BOOL(id object) {
            id <WKCollapsibleComponentTraits> p_collapsibleComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), object);
            if (p_collapsibleComponent && p_collapsibleComponent != collapsibleComponent)
            {
                return ![p_collapsibleComponent isCollapsed];
            }
            else
            {
                return NO;
            }
        }];

        [expandedComponents enumerateObjectsUsingBlock:^(NSObject <WKCollapsibleComponentTraits> *p_collapsibleComponent, NSUInteger idx, BOOL *_Nonnull stop) {

            [self removeObserverFromComponent:p_collapsibleComponent];

            p_collapsibleComponent.collapsed = YES;

            [self addObserverForComponent:p_collapsibleComponent];
        }];
    }
    else
    {
        [self removeObserverFromComponent:collapsibleComponent];

        collapsibleComponent.collapsed = NO;

        [self addObserverForComponent:collapsibleComponent];
    }

    [super p_childWasChangeCollapsedState:collapsibleComponent];
}

- (NSMutableArray *)buildFlattenComponents
{
    NSMutableArray *flattenComponents = [NSMutableArray array];
    for (KSNComponent *childComponent in self.components)
    {
        [flattenComponents addObjectsFromArray:[childComponent flattenComponents]];
    }
    return flattenComponents;
}

@end
