//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit
import Combine

internal extension UIResponder {

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
}

internal extension Publisher where Self.Failure == Never {
    func mainSink(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
    }
}

internal extension UIView {
    
    var height: CGFloat {
        get {
            return self.frame.size.height
        }

        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
}

internal extension CGRect {
    
    var top: CGFloat {
        get {return y + height}
        set {y = newValue - height}
    }
    
    var y: CGFloat {
        get { return self.origin.y }
        set { self.origin.y = newValue }
    }
}
