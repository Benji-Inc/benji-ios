//
//  UIControl+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

private class ClosureBox: NSObject {
    let closure: ()->()

    init (_ closure: @escaping ()->()) {
        self.closure = closure
    }

    @objc func invoke() {
        self.closure()
    }
}

private var selectionHandlerKey: UInt8 = 0
extension UIControl {

    private(set) var selectionImpact: UIImpactFeedbackGenerator? {
        get {
            return self.getAssociatedObject(&selectionHandlerKey)
        }
        set {
            self.setAssociatedObject(key: &selectionHandlerKey, value: newValue)
        }
    }

    func didSelect(for event: UIControl.Event = .touchUpInside,_ completion: CompletionOptional) {
        self.selectionImpact = UIImpactFeedbackGenerator()
        self.addAction(for: .touchUpInside) { [unowned self] in
            self.selectionImpact?.impactOccurred()
            completion?()
        }
    }

    @discardableResult
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping ()->()) -> AnyObject {

        // Create a proxy object to hold on to the closure, and add it as an event handler
        let box = ClosureBox(closure)
        self.addTarget(box, action: #selector(box.invoke), for: controlEvents)

        // Add this proxy object to the set of event handlers
        var boxes = self.boxes ?? Set<ClosureBox>()
        boxes.insert(box)
        self.boxes = boxes

        // Return the object in case the caller wants to remove it later
        return box
    }

    func removeAction(_ action: AnyObject?) {
        guard let box = action as? ClosureBox else { return }
        self.removeTarget(box, action: #selector(box.invoke), for: .allEvents)

        guard var boxes = self.boxes else { return }

        boxes.remove(box)
        self.boxes = boxes
    }
}


private var boxesKey: UInt8 = 0
private extension UIControl {
    var boxes: Set<ClosureBox>? {
        get {
            return self.getAssociatedObject(&boxesKey)
        }
        set {
            self.setAssociatedObject(key: &boxesKey, value: newValue)
        }
    }
}
