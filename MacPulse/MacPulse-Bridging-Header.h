#ifndef MacPulse_Bridging_Header_h
#define MacPulse_Bridging_Header_h

#include <IOKit/IOKitLib.h>
#include <libproc.h>
#include <mach/mach_host.h>
#include <mach/processor_info.h>
#include <ifaddrs.h>
#include <net/if.h>

// IOReport functions - undocumented but stable C API in IOKit
// CF_RETURNS_RETAINED is added for functions following Create/Copy naming convention

CF_RETURNS_RETAINED
extern CFDictionaryRef _Nullable IOReportCopyAllChannels(uint64_t a, uint64_t b);

CF_RETURNS_RETAINED
extern CFDictionaryRef _Nullable IOReportCopyChannelsInGroup(CFStringRef _Nonnull group, CFStringRef _Nullable subgroup, uint64_t a, uint64_t b, uint64_t c);

CF_RETURNS_RETAINED
extern CFMutableDictionaryRef _Nullable IOReportMergeChannels(CFDictionaryRef _Nonnull a, CFDictionaryRef _Nonnull b, CFTypeRef _Nullable c);

CF_RETURNS_RETAINED
extern CFDictionaryRef _Nullable IOReportCreateSubscription(void * _Nullable a, CFMutableDictionaryRef _Nonnull channels, CFMutableDictionaryRef _Nullable * _Nullable subscribed, uint64_t channel_id, CFTypeRef _Nullable b);

CF_RETURNS_RETAINED
extern CFDictionaryRef _Nullable IOReportCreateSamples(CFDictionaryRef _Nonnull subscription, CFMutableDictionaryRef _Nonnull channels, CFTypeRef _Nullable a);

CF_RETURNS_RETAINED
extern CFDictionaryRef _Nullable IOReportCreateSamplesDelta(CFDictionaryRef _Nonnull prev, CFDictionaryRef _Nonnull current, CFTypeRef _Nullable a);

typedef int IOReportIterationResult;
typedef IOReportIterationResult (^IOReportIteratorBlock)(CFDictionaryRef _Nonnull channel);
extern void IOReportIterate(CFDictionaryRef _Nonnull samples, IOReportIteratorBlock _Nonnull block);

CF_RETURNS_NOT_RETAINED
extern CFStringRef _Nullable IOReportChannelGetGroup(CFDictionaryRef _Nonnull channel);

CF_RETURNS_NOT_RETAINED
extern CFStringRef _Nullable IOReportChannelGetSubGroup(CFDictionaryRef _Nonnull channel);

CF_RETURNS_NOT_RETAINED
extern CFStringRef _Nullable IOReportChannelGetChannelName(CFDictionaryRef _Nonnull channel);

extern int64_t IOReportSimpleGetIntegerValue(CFDictionaryRef _Nonnull channel, int32_t index);
extern long IOReportStateGetCount(CFDictionaryRef _Nonnull channel);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef _Nonnull channel, int32_t index);

CF_RETURNS_NOT_RETAINED
extern CFStringRef _Nullable IOReportStateGetNameForIndex(CFDictionaryRef _Nonnull channel, int32_t index);

#endif
