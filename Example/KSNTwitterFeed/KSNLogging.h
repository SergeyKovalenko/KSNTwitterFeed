//
//  KSNLogging.h
//
//  Created by Sergey Kovalenko on 2/18/16.
//  Copyright © 2016. All rights reserved.
//

#ifndef KSNLogging_h
#define KSNLogging_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#undef LOG_LEVEL_DEF // Undefine first only if needed

#ifdef DEBUG

#define LOG_LEVEL_DEF DDLogLevelDebug

#else

#define LOG_LEVEL_DEF DDLogLevelWarning

#endif

#undef LOG
#define LOG(frmt, ...)         LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LOG_ERROR(frmt, ...)   LOG_MAYBE(NO, LOG_LEVEL_DEF, DDLogFlagError, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#endif /* KSNLogging_h */
