import CoreData
extension Sequence where Iterator.Element: NSManagedObject {
    func remap(to context: NSManagedObjectContext) -> [Iterator.Element] {
        return map { unmappedMO in
            guard unmappedMO.managedObjectContext !== context else { return unmappedMO }
            guard let object = context.object(with: unmappedMO.objectID) as? Iterator.Element else { fatalError("Invalid object type") }
            return object
        }
    }
}
extension NSManagedObject {
    func changedValue(forKey key: String) -> Any? {
        return changedValues()[key]
    }
}
