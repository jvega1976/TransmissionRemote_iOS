//
//  NSObjectExtension.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import Foundation



extension NSObject {
    
    private static var selectedFlag = 0
    
    var dataObject: Any? {
        get {
            return objc_getAssociatedObject(self, &NSObject.selectedFlag)
        }
        set(dataObject) {
            objc_setAssociatedObject(self, &NSObject.selectedFlag, dataObject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
