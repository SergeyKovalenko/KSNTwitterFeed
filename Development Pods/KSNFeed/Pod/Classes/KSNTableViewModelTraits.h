//
//  KSNTableViewModelTraits.h

//
//  Created by Sergey Kovalenko on 11/2/14.
//  Copyright (c) 2014. All rights reserved.
//

@protocol KSNTableViewModelTraits <NSObject>
@optional

- (void)configureTableView:(UITableView *)tableView;

- (void)tableViewWillAppear:(UITableView *)tableView;

- (void)tableViewDidAppear:(UITableView *)tableView;

- (void)tableViewRefreshed:(UITableView *)tableView;

- (UITableViewStyle)tableStyle;

- (UITableViewCellSeparatorStyle)separatorStyle;
/**
 *  cellClasses
 *
 *  @return  {Cell reuse ID: Cell class} mapping for all cell classes supported by the view model.
 */
- (NSDictionary *)cellClasses;

/**
 *  nibs
 *
 *  @return {Cell reuse ID: Cell nib} mapping for all cell nibs supported by the view model.
 */
- (NSDictionary *)cellNibs;

/**
 *  cellReuseIdAtIndexPath
 *
 *  @return Reuse id at index path
 */
- (NSString *)cellReuseIdAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  cellHeightAtIndexPath
 *
 *  @return Height for the cell at the given index path
 */
- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)ip forTableView:(UITableView *)tableView;

- (CGFloat)estimatedCellHeightAtIndexPath:(NSIndexPath *)ip forTableView:(UITableView *)tableView;

/**
 *  customizeCell
 *
 *  Configure the cell
 */
- (void)customizeCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)ip;


/**
*  viewForHeaderInSection
*
*  Section title / footer for section index.
*/
- (NSString *)titleForHeaderInSection:(NSInteger)section;
- (NSString *)titleForFooterInSection:(NSInteger)section;

/**
 *  viewForHeaderInSection
 *
 *  Header view for section index.
 */
- (UIView *)viewForHeaderInSection:(NSInteger)section;
- (UIView *)viewForFooterInSection:(NSInteger)section;

/**
 *  heightForHeaderInSection
 *
 *  @return Height for the header view at the given section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (CGFloat)heightForFooterInSection:(NSInteger)section;
- (CGFloat)estimatedHeightForHeaderInSection:(NSInteger)section;
- (CGFloat)estimatedHeightForFooterInSection:(NSInteger)section;

/**
 *  tableViewDidSetEditing
 *
 *  @param editing
 */
- (void)tableViewDidSetEditing:(BOOL)editing;

/**
 *  didSelectCell:atIndexPath:selectedIndexes
 *
 *  @param cell       selected cell
 *  @param ip         selected cell index path
 *  @param indexPaths all selected indexes
 */
- (void)tableView:(UITableView *)tableView didSelectCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)ip selectedIndexes:(NSArray *)indexPaths;

/**
 *  didDeselectCell:atIndexPath:selectedIndexes
 *
 *  @param cell       deselected cell
 *  @param ip         deselected cell index path
 *  @param indexPaths all selected indexes
 */
- (void)tableView:(UITableView *)tableView didDeselectCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)ip selectedIndexes:(NSArray *)indexPaths;

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

- (void)tableViewDidScroll:(UITableView *)tableView;


@end

