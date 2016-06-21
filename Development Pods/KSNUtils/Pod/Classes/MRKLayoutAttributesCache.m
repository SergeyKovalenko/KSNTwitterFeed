//
//  MRKLayoutAttributesCache.m
//
//  Created by Sergey Kovalenko on 3/4/16.
//  Copyright © 2016. All rights reserved.
//

#import "MRKLayoutAttributesCache.h"

@interface MRKLayoutAttributesCache ()

@property (nonatomic, strong) NSMutableDictionary *itemsLayoutInformationByIndexPath;
@property (nonatomic, strong) NSMutableDictionary *supplementaryViewOfKind;
@property (nonatomic, strong) NSMutableDictionary *decorationViewOfKind;
@property (nonatomic, strong) NSMutableSet *attributesSet;
@end

@implementation MRKLayoutAttributesCache

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.itemsLayoutInformationByIndexPath = [NSMutableDictionary dictionary];
        self.supplementaryViewOfKind = [NSMutableDictionary dictionary];
        self.decorationViewOfKind = [NSMutableDictionary dictionary];
        self.attributesSet = [NSMutableSet set];
    }

    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    return [self.attributesSet countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSArray *)allLayoutAttribute
{
    return [self.attributesSet allObjects];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath
{
    return self.itemsLayoutInformationByIndexPath[indexPath];
}

- (BOOL)addLayoutAttributesForCell:(UICollectionViewLayoutAttributes *)attributes
{
    if (![self.attributesSet containsObject:attributes])
    {
        self.itemsLayoutInformationByIndexPath[attributes.indexPath] = attributes;
        [self.attributesSet addObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)removeLayoutAttributesForCell:(UICollectionViewLayoutAttributes *)attributes
{
    if ([self.attributesSet containsObject:attributes])
    {
        [self.itemsLayoutInformationByIndexPath removeObjectForKey:attributes.indexPath];
        [self.attributesSet removeObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryViewOfKind[elementKind][indexPath];
}

- (BOOL)addLayoutAttributesForSupplementaryView:(UICollectionViewLayoutAttributes *)attributes
{
    if (![self.attributesSet containsObject:attributes])
    {
        NSMutableDictionary *supplementaryByIndexPath = self.supplementaryViewOfKind[attributes.representedElementKind];
        if (!supplementaryByIndexPath)
        {
            supplementaryByIndexPath = [NSMutableDictionary dictionary];
            self.supplementaryViewOfKind[attributes.representedElementKind] = supplementaryByIndexPath;
        }

        supplementaryByIndexPath[attributes.indexPath] = attributes;
        [self.attributesSet addObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)removeLayoutAttributesForSupplementaryView:(UICollectionViewLayoutAttributes *)attributes
{
    if ([self.attributesSet containsObject:attributes])
    {
        NSMutableDictionary *supplementaryByIndexPath = self.supplementaryViewOfKind[attributes.representedElementKind];
        [supplementaryByIndexPath removeObjectForKey:attributes.indexPath];
        [self.attributesSet removeObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind withIndexPath:(NSIndexPath *)indexPath
{
    return self.decorationViewOfKind[decorationViewKind][indexPath];
}

- (void)enumerateLayoutAttributesForDecorationViewsUsingBlock:(void (^)(NSString *decorationViewKind, NSIndexPath *idx, UICollectionViewLayoutAttributes *attributes, BOOL *stop))block
{
    if (block)
    {
        [self.decorationViewOfKind enumerateKeysAndObjectsUsingBlock:^(NSString *decorationViewKind, NSMutableDictionary *decorationByIndexPath, BOOL *stopKindsEnumeration) {
            [decorationByIndexPath enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stopIndexPathEnumeration) {
                BOOL stop = NO;
                block(decorationViewKind, indexPath, attributes, &stop);
                *stopIndexPathEnumeration = stop;
                *stopKindsEnumeration = stop;
            }];
        }];
    }
}

- (BOOL)addLayoutAttributesForDecorationView:(UICollectionViewLayoutAttributes *)attributes
{
    if (![self.attributesSet containsObject:attributes])
    {
        NSMutableDictionary *decorationByIndexPath = self.decorationViewOfKind[attributes.representedElementKind];
        if (!decorationByIndexPath)
        {
            decorationByIndexPath = [NSMutableDictionary dictionary];
            self.decorationViewOfKind[attributes.representedElementKind] = decorationByIndexPath;
        }

        decorationByIndexPath[attributes.indexPath] = attributes;
        [self.attributesSet addObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)removeLayoutAttributesForDecorationView:(UICollectionViewLayoutAttributes *)attributes
{
    if ([self.attributesSet containsObject:attributes])
    {
        NSMutableDictionary *decorationByIndexPath = self.decorationViewOfKind[attributes.representedElementKind];
        [decorationByIndexPath removeObjectForKey:attributes.indexPath];
        [self.attributesSet removeObject:attributes];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)addLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    BOOL added = NO;
    if (attributes.indexPath)
    {
        switch (attributes.representedElementCategory)
        {
            case UICollectionElementCategoryCell:
            {
                added = [self addLayoutAttributesForCell:attributes];
            }
                break;
            case UICollectionElementCategorySupplementaryView:
            {
                added = attributes.representedElementKind != nil && [self addLayoutAttributesForSupplementaryView:attributes];
            }
                break;
            case UICollectionElementCategoryDecorationView:
            {
                added = attributes.representedElementKind != nil && [self addLayoutAttributesForDecorationView:attributes];
            }
                break;
        }
    }

    return added;
}

- (BOOL)removeLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    BOOL removed = NO;
    if (attributes.indexPath)
    {
        switch (attributes.representedElementCategory)
        {
            case UICollectionElementCategoryCell:
            {
                removed = [self removeLayoutAttributesForCell:attributes];
            }
                break;
            case UICollectionElementCategorySupplementaryView:
            {
                removed = attributes.representedElementKind != nil && [self removeLayoutAttributesForSupplementaryView:attributes];
            }
                break;
            case UICollectionElementCategoryDecorationView:
            {
                removed = attributes.representedElementKind != nil && [self removeLayoutAttributesForDecorationView:attributes];
            }
                break;
        }
    }

    return removed;
}

- (NSArray *)indexPathsForCells;
{
    return [self.itemsLayoutInformationByIndexPath allKeys];
}

- (NSArray *)indexPathsForSupplementaryViewOfKind:(NSString *)elementKind
{
    NSMutableDictionary *supplementaryByIndexPath = self.supplementaryViewOfKind[elementKind];
    return [supplementaryByIndexPath allKeys];
}

- (NSArray *)indexPathsForDecorationViewOfKind:(NSString *)decorationViewKind
{
    NSMutableDictionary *decorationByIndexPath = self.decorationViewOfKind[decorationViewKind];
    return [decorationByIndexPath allKeys];
}

- (void)removeAllLayoutAttributes
{
    [self.itemsLayoutInformationByIndexPath removeAllObjects];
    [self.supplementaryViewOfKind removeAllObjects];
    [self.decorationViewOfKind removeAllObjects];
    [self.attributesSet removeAllObjects];
}

@end
