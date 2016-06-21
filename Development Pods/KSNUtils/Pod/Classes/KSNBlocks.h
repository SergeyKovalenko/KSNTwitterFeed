//
//  KSNBlocks.h
//  Pods
//
//  Created by Sergey Kovalenko on 2/5/16.
//
//

#ifndef KSNBlocks_h
#define KSNBlocks_h

/*!
 * @typedef:  KSNVoidBlock
 * @abstract: Basic block that neither gives nor takes.
 */
typedef void (^KSNVoidBlock)(void);

/*!
 * @typedef:  KSNStringBlock
 * @abstract: Basic block that takes an NSString.
 */
typedef void (^KSNStringBlock)(NSString *);

/*!
 * @typedef:  KSNErrorBlock
 * @abstract: Basic block that takes an NSError.
 */
typedef void (^KSNErrorBlock)(NSError *);

/*!
 * @typedef:  KSNSenderBlock
 * @abstract: A block that takes a single object.
 */
typedef void (^KSNSenderBlock)(id sender);

/*!
 * @typedef:  KSNBooleanBlock
 * @abstract: A block that takes a `BOOL`
 */
typedef void (^KSNBooleanBlock)(BOOL);

#endif /* KSNBlocks_h */
