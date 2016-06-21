//
//  KSNComponent.h
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

@protocol KSNComponentTraits <NSObject, NSFastEnumeration>

@property (nonatomic, weak, readonly) id <KSNComponentTraits> parent;
@property (nonatomic, strong, readonly) NSArray *childs;

- (void)addComponent:(id <KSNComponentTraits>)component;
- (BOOL)containsComponent:(id <KSNComponentTraits>)component;
- (void)removeComponent:(id <KSNComponentTraits>)component;
- (void)removeAllComponents;

- (NSUInteger)count;
@end

@interface KSNComponent : NSObject <KSNComponentTraits>

- (instancetype)initWithValue:(id)value;

+ (NSArray *)componentsForValues:(id <NSFastEnumeration, NSObject>)values factoryBlock:(id <KSNComponentTraits>(^)(id value))factoryBlock;
+ (NSArray *)componentsForValues:(id <NSFastEnumeration, NSObject>)values adjustingBlock:(void (^)(id <KSNComponentTraits> component))adjustingBlock;

@property (nonatomic, strong) id value;
@property (nonatomic, readonly) NSArray *flattenComponents;

@end