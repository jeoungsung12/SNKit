//
//  ObjectAssociation.swift
//  SNKit
//
//  Created by 정성윤 on 6/4/25.
//

import Foundation

final class ObjectAssociation<T> {
    private let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
    
    subscript(index: AnyObject) -> T? {
        get {
            return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? T
        }
        set {
            objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy)
        }
    }
}
