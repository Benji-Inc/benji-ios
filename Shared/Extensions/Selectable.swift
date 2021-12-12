//
//  Selectable.swift
//  Benji
//
//  Created by Benji Dodgson on 12/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol Selectable {
    func didSelect(_ completion: CompletionOptional)
}

private var selectionHandlerKey: UInt8 = 0
private var didSelectHandlerKey: UInt8 = 0
private var actionHandlerKey: UInt = 0
extension Selectable where Self: UIControl {

    private(set) var selectionImpact: UIImpactFeedbackGenerator? {
        get {
            return self.getAssociatedObject(&selectionHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &selectionHandlerKey, value: newValue)
        }
    }
    
    private(set) var action: UIAction? {
        get {
            return self.getAssociatedObject(&actionHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &actionHandlerKey, value: newValue)
        }
    }

    var isActive: Bool {
        return !self.selectionImpact.isNil
    }

    func didSelect(_ completion: CompletionOptional) {
        if let action = self.action {
            self.removeAction( action, for: .touchUpInside)
        }
        
        self.selectionImpact = UIImpactFeedbackGenerator()
        self.action = UIAction { action in
            completion?()
        }

        self.addAction(self.action!, for: .touchUpInside)
    }
}

private var tapHandlerKey: UInt = 0
extension Selectable where Self: UIView {

    private(set) var tapRecognizer: UITapGestureRecognizer? {
        get {
            return self.getAssociatedObject(&tapHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &tapHandlerKey, value: newValue)
        }
    }

    private(set) var selectionImpact: UIImpactFeedbackGenerator? {
        get {
            return self.getAssociatedObject(&selectionHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &selectionHandlerKey, value: newValue)
        }
    }

    func didSelect(_ completion: CompletionOptional) {
        self.selectionImpact = UIImpactFeedbackGenerator()

        // Remove the previous tap gesture recognizer so we don't call did select twice.
        if let tapRecognizer = self.tapRecognizer {
            self.removeGestureRecognizer(tapRecognizer)
        }

//        let tapRecognizer = UITapGestureRecognizer(taps: 1) { [unowned self] (_) in
//            self.selectionImpact?.impactOccurred()
//            completion?()
//        }
//        self.addGestureRecognizer(tapRecognizer)
//        self.tapRecognizer = tapRecognizer
    }
}
