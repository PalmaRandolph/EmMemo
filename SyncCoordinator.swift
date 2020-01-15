import UIKit
import CoreData
import CloudKit
import Kuery
typealias SyncFlag = SyncCoordinator.Flag
protocol ObserverTokenStore: class {
    func addObserverToken(_ token: NSObjectProtocol)
}
final class SyncCoordinator {
    enum Flag: String {
        case markedForUploadReserved
        case markedForRemoteDeletion
        case markedForDeletionDate
    }
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    let syncGroup = DispatchGroup()
    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    var teardownFlag = atomic_flag()
    let remote: RemoteProvider
    fileprivate var observerTokens = [NSObjectProtocol]()
    let changeProcessors: [ChangeProcessor]
    var didPerformDelayed = false
    private lazy var reachability = Reachability()
    public init(
        container: NSPersistentContainer,
        remoteProvider: RemoteProvider,
        changeProcessors: [ChangeProcessor]) {
        viewContext = container.viewContext
        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy.overwrite
        viewContext.mergePolicy = NSMergePolicy.overwrite
        viewContext.name = "View Context"
        backgroundContext.name = "Background Context"
        remote = remoteProvider
        self.changeProcessors = changeProcessors
        setup()
    }
    public func tearDown() {
        guard !atomic_flag_test_and_set(&teardownFlag) else { return }
        perform {
            self.removeAllObserverTokens()
        }
    }
    deinit {
        guard atomic_flag_test_and_set(&teardownFlag) else { fatalError("deinit called without tearDown() being called.") }
    }
    fileprivate func setup() {
        perform {
            self.setupContexts()
            self.setupApplicationActiveNotifications()
            self.remote.setup(context: self.backgroundContext)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(performDelayed(_:)),
            name: .didFinishHandleZoneChange, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchRemoteDataForApplicationDidBecomeActive),
            name: .fetchDataFromRemote, object: nil
        )
    }
    @objc func performDelayed(_ notification: Notification) {
        guard !didPerformDelayed else { return }
        let addTutorial = AddTutorialOperation(context: viewContext)
        let completion = BlockOperation { [unowned self] in
            self.didPerformDelayed = true
        }
        privateQueue.addOperations([addTutorial, completion], waitUntilFinished: false)
    }
    func saveContexts() {
        backgroundContext.saveOrRollback()
        viewContext.saveOrRollback()
    }
    func registerReachabilityNotification() {
        guard let reachability = reachability else { return }
        reachability.whenReachable = {
            [weak self] reachability in
            guard let self = self else { return }
            self.fetchLocallyTrackedObjects()
        }
        do {
            try reachability.startNotifier()
        } catch {
            print(error)
        }
    }
}
extension Sequence {
    func asyncForEach(completion: @escaping () -> Void, block: (Iterator.Element, @escaping () -> Void) -> Void) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
}
extension SyncCoordinator: ChangeProcessorContext {
    var context: NSManagedObjectContext {
        return backgroundContext
    }
    func perform(_ block: @escaping () -> Void) {
        backgroundContext.perform(group: syncGroup, block: block)
    }
    func delayedSaveOrRollback() {
        context.saveOrRollback()
    }
}
extension SyncCoordinator: ContextOwner {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }
    func removeAllObserverTokens() {
        observerTokens.removeAll()
    }
    func processChangedLocalObjects(_ objects: [NSManagedObject]) {
        for cp in changeProcessors {
            cp.processChangedLocalObjects(objects, in: self)
        }
    }
}
extension SyncCoordinator: ApplicationActiveStateObserving {
    func applicationDidBecomeActive() {
        fetchLocallyTrackedObjects()
        fetchRemoteDataForApplicationDidBecomeActive()
    }
    func applicationDidEnterBackground() {
    }
    fileprivate func fetchLocallyTrackedObjects() {
        backgroundContext.performAndWait {
            var objects = Set<NSManagedObject>()
            for cp in changeProcessors {
                guard let entityAndPredicate = cp.entityAndPredicateForLocallyTrackedObjects(in: self)
                    else { continue }
                let request = entityAndPredicate.fetchRequest
                request.returnsObjectsAsFaults = false
                do {
                    let result = try backgroundContext.fetch(request)
                    objects.formUnion(result)
                } catch {
                    print(error)
                }
            }
            self.processChangedLocalObjects(Array(objects))
        }
    }
}
extension SyncCoordinator {
    @objc fileprivate func fetchRemoteDataForApplicationDidBecomeActive() {
        remote.fetchChanges(in: .private, needByPass: false, needRefreshToken: false) { _ in}
        UserDefaults.standard.set(Date.init(), forKey: "lastBackupDate")
    }
}
