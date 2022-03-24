//
//  UIResponder+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 2/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import UIKit

extension UIResponder {

    private weak static var currentFirstResponder: UIResponder?

    /// Returns the UIResponder that is currently designated as first responder. Nil is returned if there is no current first responder.
    static var firstResponder: UIResponder? {
        UIResponder.currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)),
                                        to: nil,
                                        from: nil,
                                        for: nil)
        return UIResponder.currentFirstResponder
    }

    @objc private func findFirstResponder(sender: AnyObject) {
        UIResponder.currentFirstResponder = self
    }
    
    func responderChain() -> String {
        guard let next = next else {
            return NSStringFromClass(type(of: self))//String(describing: self)
        }
        return NSStringFromClass(type(of: self)) + " -> " + next.responderChain()
    }
}
