#include "KeelSystemShims.h"

#ifdef __APPLE__
#include <string.h>
#include <CoreFoundation/CoreFoundation.h>

// MARK: - SMC

// The AppleSMC user client's structures, as every SMC reader uses them.
enum { KEEL_SMC_KERNEL_INDEX = 2, KEEL_SMC_READ_KEY = 5, KEEL_SMC_GET_KEY_INFO = 9 };

typedef struct {
    char major, minor, build, reserved;
    uint16_t release;
} keel_smc_version;

typedef struct {
    uint16_t version, length;
    uint32_t cpuPLimit, gpuPLimit, memPLimit;
} keel_smc_plimit;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t dataAttributes;
} keel_smc_key_info;

typedef struct {
    uint32_t key;
    keel_smc_version vers;
    keel_smc_plimit pLimitData;
    keel_smc_key_info keyInfo;
    uint8_t result, status, data8;
    uint32_t data32;
    uint8_t bytes[32];
} keel_smc_data;

static uint32_t keel_fourcc(const char *text) {
    return ((uint32_t)(uint8_t)text[0] << 24) | ((uint32_t)(uint8_t)text[1] << 16)
        | ((uint32_t)(uint8_t)text[2] << 8) | (uint32_t)(uint8_t)text[3];
}

io_connect_t keel_smc_open(void) {
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return 0;
    io_connect_t connection = 0;
    kern_return_t result = IOServiceOpen(service, mach_task_self(), 0, &connection);
    IOObjectRelease(service);
    return result == KERN_SUCCESS ? connection : 0;
}

void keel_smc_close(io_connect_t connection) {
    if (connection) IOServiceClose(connection);
}

static kern_return_t keel_smc_call(io_connect_t connection, keel_smc_data *input, keel_smc_data *output) {
    size_t outputSize = sizeof(keel_smc_data);
    return IOConnectCallStructMethod(connection, KEEL_SMC_KERNEL_INDEX, input, sizeof(keel_smc_data), output, &outputSize);
}

int keel_smc_read(io_connect_t connection, const char *key, keel_smc_value *value) {
    if (!connection || !key || strlen(key) != 4 || !value) return -1;
    keel_smc_data input, output;
    memset(&input, 0, sizeof input);
    memset(&output, 0, sizeof output);

    input.key = keel_fourcc(key);
    input.data8 = KEEL_SMC_GET_KEY_INFO;
    if (keel_smc_call(connection, &input, &output) != KERN_SUCCESS || output.result != 0) return -1;
    uint32_t size = output.keyInfo.dataSize;
    uint32_t type = output.keyInfo.dataType;
    if (size == 0 || size > 32) return -1;

    input.keyInfo.dataSize = size;
    input.data8 = KEEL_SMC_READ_KEY;
    memset(&output, 0, sizeof output);
    if (keel_smc_call(connection, &input, &output) != KERN_SUCCESS || output.result != 0) return -1;

    value->type[0] = (char)(type >> 24);
    value->type[1] = (char)(type >> 16);
    value->type[2] = (char)(type >> 8);
    value->type[3] = (char)type;
    value->type[4] = 0;
    value->size = size;
    memcpy(value->bytes, output.bytes, size);
    return 0;
}

// MARK: - HID temperature sensors

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hidsystem/IOHIDServiceClient.h>

// The client, its services and their properties are public API. Creating a
// full client, matching and reading an event are not in the headers, but
// IOKit exports them and Activity Monitor-like tools use them to read Apple
// silicon's temperature sensors. Declared here only, so nothing else sees them.
typedef struct __keel_hid_event *keel_hid_event;
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef matching);
extern keel_hid_event IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t timestamp);
extern double IOHIDEventGetFloatValue(keel_hid_event event, int32_t field);

enum { KEEL_HID_TEMPERATURE_EVENT = 15, KEEL_HID_SENSOR_PAGE = 0xff00, KEEL_HID_TEMPERATURE_USAGE = 5 };

int keel_read_temperature_sensors(keel_temperature_reading *readings, int capacity) {
    if (!readings || capacity <= 0) return 0;
    IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (!client) return 0;

    int page = KEEL_HID_SENSOR_PAGE, usage = KEEL_HID_TEMPERATURE_USAGE;
    CFNumberRef pageNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &page);
    CFNumberRef usageNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage);
    const void *keys[] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
    const void *values[] = { pageNumber, usageNumber };
    CFDictionaryRef matching = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 2,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    IOHIDEventSystemClientSetMatching(client, matching);

    int count = 0;
    CFArrayRef services = IOHIDEventSystemClientCopyServices(client);
    if (services) {
        CFIndex total = CFArrayGetCount(services);
        for (CFIndex index = 0; index < total && count < capacity; index++) {
            IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, index);
            keel_hid_event event = IOHIDServiceClientCopyEvent(service, KEEL_HID_TEMPERATURE_EVENT, 0, 0);
            if (!event) continue;
            double celsius = IOHIDEventGetFloatValue(event, KEEL_HID_TEMPERATURE_EVENT << 16);
            CFRelease(event);

            CFTypeRef name = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
            readings[count].name[0] = 0;
            if (name && CFGetTypeID(name) == CFStringGetTypeID()) {
                CFStringGetCString((CFStringRef)name, readings[count].name, sizeof readings[count].name, kCFStringEncodingUTF8);
            }
            if (name) CFRelease(name);
            readings[count].celsius = celsius;
            count++;
        }
        CFRelease(services);
    }

    CFRelease(matching);
    CFRelease(pageNumber);
    CFRelease(usageNumber);
    CFRelease(client);
    return count;
}
#endif
