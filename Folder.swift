import CoreData
import CloudKit
extension Folder: Managed, UploadReservable, RemoteDeletable, DelayedDeletable {}
extension Folder {
    enum FolderType: Int {
        case custom
        case all
        case locked
        case removed
    }
    static func insert(
        into moc: NSManagedObjectContext,
        type: FolderType,
        needUpload: Bool = true) -> Folder {
        let folder: Folder = moc.insertObject()
        let id = UUID().uuidString
        folder.localID = id
        folder.createdAt = Date()
        folder.modifiedAt = Date()
        folder.isMine = true
        folder.type = Int64(type.rawValue)
        if needUpload {
            folder.markUploadReserved()
        }
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecord.ID(
            recordName: id,
            zoneID: zoneID
        )
        folder.recordArchive = CKRecord(recordType: Record.folder, recordID: ckRecordID).archived
        return folder
    }
}
