//
//  KSNCollectionViewModelTraits.h
//
//  Created by Sergey Kovalenko on 2/6/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KSNCollectionViewModelTraits <NSObject>

@required

@property (nonatomic, strong, readonly) UICollectionViewLayout *layout;

@optional

- (void)configureCollectionView:(UICollectionView *)collectionView;

/**
*  cellClasses
*
*  @return  {Cell reuse ID: Cell class} mapping for all cell classes supported by the view model.
*/
- (NSDictionary *)cellClasses;

/**
*  cellNibs
*
*  @return {Cell reuse ID: Cell nib} mapping for all cell nibs supported by the view model.
*/
- (NSDictionary *)cellNibs;

/**
*  supplementaryViewClasses
*
*  @return  {reuseID : {kind : class}} mapping for all supplementary view classes supported by the view model.
*/
- (NSDictionary *)supplementaryViewClasses;

/**
*  nibs
*
*  @return {reuseID : {kind : nib}} mapping for all supplementary view nibs supported by the view model.
*/
- (NSDictionary *)supplementaryViewNibs;

/**
*  cellReuseIdAtIndexPath
*
*  @return Reuse id of cell at index path
*/
- (NSString *)cellReuseIdAtIndexPath:(NSIndexPath *)indexPath;

/**
*  supplementaryViewReuseIdOfKind: atIndexPath:
*
*  @return Reuse id of supplementary view at index path
*/
- (NSString *)supplementaryViewReuseIdOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
*  cellHeightAtIndexPath
*
*  @return Height for the cell at the given index path
*/
- (CGSize)cellSizeAtIndexPath:(NSIndexPath *)ip forCollectionView:(UICollectionView *)collectionView;

/**
*  customizeCell: forCollectionView: atIndexPath:
*
*  Configure the cell
*/
- (void)customizeCell:(UICollectionViewCell *)cell forCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)ip;

/**
*  supplementaryViewOfKind: withReuseIdentifier: forIndexPath:
*
*  Header view for section index.
*/

- (void)customizeSupplementaryVie:(UICollectionReusableView *)supplementaryView
                forCollectionView:(UICollectionView *)collectionView
                           OfKind:(NSString *)elementKind
                     forIndexPath:(NSIndexPath *)indexPath;

/**
*  heightForHeaderInSection
*
*  @return Size for the header view at the given section.
*/
- (CGSize)sizeForHeaderInSection:(NSInteger)section forCollectionView:(UICollectionView *)collectionView;

/**
*  didSelectCell:atIndexPath:selectedIndexes
*
*  @param cell       selected cell
*  @param ip         selected cell index path
*  @param indexPaths all selected indexes
*/
- (void)didSelectCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)ip selectedIndexes:(NSArray *)indexPaths;

/**
*  didDeselectCell:atIndexPath:selectedIndexes
*
*  @param cell       deselected cell
*  @param ip         deselected cell index path
*  @param indexPaths all selected indexes
*/
- (void)didDeselectCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)ip selectedIndexes:(NSArray *)indexPaths;

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath isHeld:(BOOL)held;

@end
