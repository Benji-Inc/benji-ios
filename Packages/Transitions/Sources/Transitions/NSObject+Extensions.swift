//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation

extension NSObject {

    static var objectIdentifier: String {
        //
        return self.description()
    }

    static var objectName: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }

    var objectName: String {
        return type(of: self).description().components(separatedBy: ".").last!
    }

    func getAssociatedObject<T>(_ key: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, key) as? T
    }

    func setAssociatedObject(key: UnsafeRawPointer,
                             value: Any?,
                             policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {

        objc_setAssociatedObject(self,
                                 key,
                                 value,
                                 policy)
    }
}
