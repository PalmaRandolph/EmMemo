import Foundation
final class FolderUploder: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Folder>()
    var predicateForLocallyTrackedElements: NSPredicate {
        return NSPredicate(format: "%K == true", SyncFlag.markedForUploadReserved.rawValue)
    }
}
