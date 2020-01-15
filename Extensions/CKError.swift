import CloudKit
extension CKError {
    public func isRecordNotFound() -> Bool {
        return isZoneNotFound() || isUnknownItem()
    }
    public func isZoneNotFound() -> Bool {
        return isSpecificErrorCode(code: .zoneNotFound)
    }
    public func isUnknownItem() -> Bool {
        return isSpecificErrorCode(code: .unknownItem)
    }
    public func isConflict() -> Bool {
        return isSpecificErrorCode(code: .serverRecordChanged)
    }
    public func isSpecificErrorCode(code: CKError.Code) -> Bool {
        var match = false
        if self.code == code { match = true } else if self.code == .partialFailure {
            guard let errors = partialErrorsByItemID else { return false }
            for (_, error) in errors {
                if let cloudError = error as? CKError {
                    if cloudError.code == code {
                        match = true
                        break
                    }
                }
            }
        }
        return match
    }
    public func getMergeRecords() -> (CKRecord?, CKRecord?, CKRecord?) {
        if code == .serverRecordChanged {
            return (ancestorRecord, clientRecord, serverRecord)
        }
        guard code == .partialFailure,
            let errors = partialErrorsByItemID else {return (nil, nil, nil)}
        for (_, error) in errors {
            if let cloudError = error as? CKError {
                if cloudError.code == .serverRecordChanged {
                    return cloudError.getMergeRecords()
                }
            }
        }
        return (nil, nil, nil)
    }
}
