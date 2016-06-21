//
//  MRKLayoutAttributesCache.h
//
//  Created by Sergey Kovalenko on 3/4/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MRKLayoutAttributesCache : NSObject <NSFastEnumeration>

- (UICollectionViewLayoutAttributes *)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind withIndexPath:(NSIndexPath *)indexPath;

- (void)enumerateLayoutAttributesForDecorationViewsUsingBlock:(void (^)(NSString *decorationViewKind, NSIndexPath *idx, UICollectionViewLayoutAttributes *attributes, BOOL *stop))block;

- (NSArray *)allLayoutAttribute;

- (NSArray *)indexPathsForCells;
- (NSArray *)indexPathsForSupplementaryViewOfKind:(NSString *)elementKind;
- (NSArray *)indexPathsForDecorationViewOfKind:(NSString *)decorationViewKind;

- (BOOL)addLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (BOOL)removeLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;

- (void)removeAllLayoutAttributes;

@end
