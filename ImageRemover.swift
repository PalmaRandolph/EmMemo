import Foundation
final class ImageRemover: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .remove
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<ImageAttachment>()
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = ImageAttachment.markedForRemoteDeletionPredicate
        let notDeleted = ImageAttachment.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
}
