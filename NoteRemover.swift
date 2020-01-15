import Foundation
final class NoteRemover: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .remove
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Note>()
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Note.markedForRemoteDeletionPredicate
        let notDeleted = Note.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
}
