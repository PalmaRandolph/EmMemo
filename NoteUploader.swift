import Foundation
import CloudKit
final class NoteUploader: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Note>()
    var predicateForLocallyTrackedElements: NSPredicate {
        return NSPredicate(format: "%K == true", NoteKey.markedForUploadReserved.rawValue)
    }
}
