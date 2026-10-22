#ifndef KEEL_SYSTEM_SHIMS_H
#define KEEL_SYSTEM_SHIMS_H

#ifdef __APPLE__
#include <mach/mach.h>

/// Frees the array host_processor_info() returns. It needs mach_task_self(),
/// a mutable C global that Swift 6 refuses to reference, so it lives here.
static inline void keel_deallocate_processor_info(processor_info_array_t info, mach_msg_type_number_t count) {
    vm_deallocate(mach_task_self(), (vm_address_t)info, (vm_size_t)count * sizeof(integer_t));
}
#endif

#endif
