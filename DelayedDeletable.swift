import CoreData
protocol DelayedDeletable: class {
    var markedForDeletionDate: Date? { get set }
    func markForLocalDeletion()
}
extension DelayedDeletable {
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == NULL", NoteKey.markedForDeletionDate.rawValue)
    }
}
extension DelayedDeletable where Self: NSManagedObject {
    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
}
private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)
extension NSManagedObjectContext {
    func batchDeleteObjectsMarkedForLocalDeletion() {
        Note.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        ImageAttachment.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        Note.batchDeleteOldTrash(self)
    }
}
extension DelayedDeletable where Self: NSManagedObject, Self: Managed {
    fileprivate static func batchDeleteObjectsMarkedForLocalDeletionInContext(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", "markedForDeletionDate", cutoff as NSDate)
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeObjectIDs
        managedObjectContext.performAndWait {
            do {
                let result = try managedObjectContext.execute(batchRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as! [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [managedObjectContext]
                )
            } catch {
                print(error)
            }
        }
    }
    fileprivate static func batchDeleteOldTrash(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeObjectIDs
        managedObjectContext.performAndWait {
            do {
                let result = try managedObjectContext.execute(batchRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as! [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [managedObjectContext]
                )
            } catch {
                print(error)
            }
        }
    }
}
