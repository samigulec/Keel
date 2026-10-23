#ifndef KEEL_SYSTEM_SHIMS_H
#define KEEL_SYSTEM_SHIMS_H

#ifdef __APPLE__
#include <mach/mach.h>

/// Frees the array host_processor_info() returns. It needs mach_task_self(),
/// a mutable C global that Swift 6 refuses to reference, so it lives here.
static inline void keel_deallocate_processor_info(processor_info_array_t info, mach_msg_type_number_t count) {
    vm_deallocate(mach_task_self(), (vm_address_t)info, (vm_size_t)count * sizeof(integer_t));
}
#include <stdint.h>
#include <IOKit/IOKitLib.h>

/// One value read from the System Management Controller: its four-letter
/// type (e.g. "flt ", "fpe2", "sp78") and raw bytes.
typedef struct {
    char type[5];
    uint32_t size;
    uint8_t bytes[32];
} keel_smc_value;

/// Opens the SMC for reading; 0 when it is not available.
io_connect_t keel_smc_open(void);
void keel_smc_close(io_connect_t connection);
/// Reads a four-letter key such as "F0Ac". Returns 0 on success.
int keel_smc_read(io_connect_t connection, const char *key, keel_smc_value *value);

/// A temperature sensor reported by the HID event system (Apple silicon).
typedef struct {
    char name[64];
    double celsius;
} keel_temperature_reading;

/// Fills up to `capacity` readings and returns how many were written.
int keel_read_temperature_sensors(keel_temperature_reading *readings, int capacity);
#endif

#endif
