//
//  NSMutableArray+WKQueueAdditions.m
//  WorldKickz
//
//  Created by Sergey Kovalenko on 10/5/14.
//  Copyright (c) 2014 iChannel. All rights reserved.
//

#import "NSMutableArray+NTFQueueAdditions.h"

@implementation NSMutableArray (NTFQueueAdditions)

// Add to the tail of the queue (no one likes it when people cut in line!)
- (void)ntf_enqueue:(id)anObject
{
    [self addObject:anObject];
    //this method automatically adds to the end of the array
}

- (id)ntf_dequeue
{
    if ([self count] == 0)
    {
        return nil;
    }
    id queueObject = self[0];
    [self removeObjectAtIndex:0];       // beginning of the array is the back of the queue
    return queueObject;
}

- (id)ntf_peek:(NSInteger)index
{
    if (self.count == 0 || index < 0)
    {
        return nil;
    }
    return self[index];
}

// if there aren't any objects in the queue
// peek returns nil, and we will too
- (id)ntf_peekHead
{
    return [self ntf_peek:0];
}

// if 0 objects, we call peek:-1 which returns nil
- (id)ntf_peekTail
{
    return [self ntf_peek:self.count - 1];
}

- (BOOL)ntf_empty
{
    return self.count == 0;
}

@end
