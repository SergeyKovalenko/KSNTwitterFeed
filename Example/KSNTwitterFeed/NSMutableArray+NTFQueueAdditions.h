//
//  NSMutableArray+NTFQueueAdditions.h
//  
//
//  Created by Sergey Kovalenko on 2/3/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (NTFQueueAdditions)

- (id)ntf_dequeue;
- (void)ntf_enqueue:(id)obj;
- (id)ntf_peek:(NSInteger)index;
- (id)ntf_peekHead;
- (id)ntf_peekTail;
- (BOOL)ntf_empty;
@end
