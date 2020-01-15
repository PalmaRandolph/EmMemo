import CoreData
protocol UploadReservable: class {
    var markedForUploadReserved: Bool { get set }
    func markUploadReserved()
    func resolveUploadReserved()
}
extension UploadReservable where Self: NSManagedObject {
    func markUploadReserved() {
        markedForUploadReserved = true
    }
    func resolveUploadReserved() {
        if markedForUploadReserved {
            markedForUploadReserved = false
        }
    }
}
