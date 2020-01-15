import Foundation
import CloudKit
typealias RecordWrapper = (Bool, CKRecord)
extension CKRecord {
    var archived: Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return Data(referencing: data)
    }
    var isShared: Bool {
        return share != nil
    }
    var modifiedAtLocally: NSDate? {
        return self[NoteField.modifiedAtLocally] as? NSDate
    }
}
extension Note {
    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}
extension ImageAttachment {
    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}
