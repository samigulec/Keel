import Foundation

#if os(macOS)
import IOKit

/// Reads property dictionaries of IOKit services, e.g. the GPU or the battery.
enum IORegistry {
    static func properties(ofServicesNamed className: String) -> [[String: Any]] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(className), &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var results: [[String: Any]] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            var unmanaged: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let properties = unmanaged?.takeRetainedValue() as? [String: Any] {
                results.append(properties)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return results
    }
}
#endif

/// IOKit numbers arrive as NSNumber, Int or UInt64 depending on the key.
func ioNumber(_ value: Any?) -> Int64? {
    switch value {
    case let number as NSNumber: number.int64Value
    case let int as Int: Int64(int)
    case let int64 as Int64: int64
    case let uint64 as UInt64: Int64(clamping: uint64)
    default: nil
    }
}
