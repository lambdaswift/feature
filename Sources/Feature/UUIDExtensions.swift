import Foundation

/// Extension providing additional initializers for UUID.
extension UUID {
    /// Creates a UUID from an integer value.
    ///
    /// This initializer creates a UUID by formatting the integer value into the last 12 characters
    /// of the UUID string, while keeping the first 24 characters as zeros. The resulting UUID
    /// will be in the format: `00000000-0000-0000-0000-XXXXXXXXXXXX` where X represents
    /// the hexadecimal representation of the integer value.
    ///
    /// - Parameter intValue: The integer value to convert into a UUID.
    public init(_ intValue: Int) {
        self.init(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", intValue))")!
    }
}
