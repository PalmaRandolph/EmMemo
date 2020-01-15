import Foundation
import CloudKit
protocol RequestResultsProvider {
    var savedRecords: [CKRecord]? { get }
    var deletedRecordIDs: [CKRecord.ID]? { get }
    var operationError: Error? { get }
    var database: CKDatabase? { get }
}
