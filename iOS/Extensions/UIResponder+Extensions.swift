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
}
