//
//  Selectable.swift
//  Benji
//
//  Created by Benji Dodgson on 12/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import GestureRecognizerClosures

protocol Selectable {
    func didSelect(_ completion: CompletionOptional)
}

private var selectionHandlerKey: UInt8 = 0
private var didSelectHandlerKey: UInt8 = 0
extension Selectable where Self: UIControl {

    private(set) var selectionImpact: UIImpactFeedbackGenerator? {
        get {
            return self.getAssociatedObject(&selectionHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &selectionHandlerKey, value: newValue)
        }
    }

    var isActive: Bool {
        return !self.selectionImpact.isNil
    }

    func didSelect(_ completion: CompletionOptional) {
        self.didSelect(for: .touchUpInside, completion)
    }

    private func didSelect(for event: UIControl.Event,_ completion: CompletionOptional) {
        self.selectionImpact = UIImpactFeedbackGenerator()
        self.addAction(for: .touchUpInside) { [unowned self] in
            self.selectionImpact?.impactOccurred()
            completion?()
        }
    }
}

extension Selectable where Self: UIView {

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
        let tap = UITapGestureRecognizer(taps: 1) { [unowned self] (_) in
            self.selectionImpact?.impactOccurred()
            completion?()
        }
        self.addGestureRecognizer(tap)
    }
}
