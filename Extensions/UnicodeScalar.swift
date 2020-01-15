import Foundation
extension UnicodeScalar {
    var isEmoji: Bool {
        switch value {
        case 0x1F600...0x1F64F, 
        0x1F300...0x1F5FF, 
        0x1F680...0x1F6FF, 
        0x1F1E6...0x1F1FF, 
        0x2600...0x26FF,   
        0x2700...0x27BF,   
        0xFE00...0xFE0F,   
        0x1F900...0x1F9FF,  
        127000...127600, 
        65024...65039, 
        9100...9300, 
        8400...8447: 
            return true
        default: return false
        }
    }
    var isZeroWidthJoiner: Bool {
        return value == 8205
    }
}
