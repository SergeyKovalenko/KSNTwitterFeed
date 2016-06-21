//
//  KSNNetworkUtils.h
//
//  Created by Sergey Kovalenko on 2/5/16.
//  Copyright © 2016. All rights reserved.
//

#ifndef KSNNetworkUtils_h
#define KSNNetworkUtils_h

#ifndef KSN_RACError
#define KSN_RACError(condition, desc, ...)    \
do {                \
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {        \
return [RACSignal error:[NSError errorWithDomain:[NSString stringWithUTF8String:__FILE__] \
code:__LINE__ \
userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:(desc), ##__VA_ARGS__]}]]; \
}                \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)

#define KSN_RACParameterAssert(condition) KSN_RACError((condition), @"Invalid parameter not satisfying: %s", #condition)
#endif

#ifndef NetworkLOG
#ifdef DEBUG
#define NetworkLOG(frmt, ...) NSLog( frmt, ##__VA_ARGS__)
#else
#define NetworkLOG(frmt, ...)
#endif
#endif //LOG

#endif //KSNNetworkUtils_h