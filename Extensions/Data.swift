import Foundation
import CloudKit
extension Data {
    var ckRecorded: CKRecord? {
        let coder = NSKeyedUnarchiver(forReadingWith: self)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}
extension NSData {
    var ckRecorded: CKRecord? {
        let coder = NSKeyedUnarchiver(forReadingWith: self as Data)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}
