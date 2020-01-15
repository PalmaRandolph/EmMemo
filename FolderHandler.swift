import CoreData
import Kuery
protocol FolderHandlable: class {
    var context: NSManagedObjectContext { get }
    func create(name: String, completion: ((Folder?) -> Void)?)
    func update(folder: Folder, newName: String, completion: ChangeCompletion)
    func remove(folders: [Folder], completion: ChangeCompletion)
}
class FolderHandler: NSObject, FolderHandlable {
    let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}
extension FolderHandlable {
    func create(name: String, completion: ((Folder?) -> Void)?) {
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                let results = try Query(Folder.self).filter(\Folder.name == name).execute()
                guard results.count == 0 else {
                    completion?(nil)
                    return
                }
                let folder = Folder.insert(into: self.context, type: .custom)
                folder.name = name
                if self.context.saveOrRollback() {
                    completion?(folder)
                } else {
                    completion?(nil)
                }
            } catch {
                completion?(nil)
            }
        }
    }
    func update(folder: Folder, newName: String, completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            folder.name = newName
            if let notes = folder.notes {
                notes.forEach {
                    if let note = $0 as? Note {
                        note.markUploadReserved()
                    }
                }
            }
            completion?(self.context.saveOrRollback())
        }
    }
    func remove(folders: [Folder], completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            folders.forEach {
                if let notes = $0.notes {
                    notes.forEach {
                        if let note = $0 as? Note {
                            note.isRemoved = true
                            note.markUploadReserved()
                        }
                    }
                }
            }
            folders.forEach {
                self.context.delete($0)
            }
            completion?(self.context.saveOrRollback())
        }
    }
}
