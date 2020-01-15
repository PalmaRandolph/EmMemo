import CoreData
final class InProgressTracker<O: NSManagedObject> where O: Managed {
    fileprivate var objectsInProgress = Set<O>()
    func objectsToProcess(from objects: [O]) -> [O] {
        let added = objects.filter { !objectsInProgress.contains($0) }
        objectsInProgress.formUnion(added)
        return added
    }
    func markObjectsAsComplete(_ objects: [O]) {
        objectsInProgress.subtract(objects)
    }
}
