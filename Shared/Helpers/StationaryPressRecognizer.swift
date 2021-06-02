//
//  StationaryPressRecognizer.swift
//  Ours
//
//  Created by Benji Dodgson on 6/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit.UIGestureRecognizerSubclass

/// A gesture recognizer that looks for a single touch that doesn't move far from its starting position and is then lifted.
/// While down, the user's finger must not move more than a specified distance or the gesture fails.
/// Begins: when a touch is made to the view.
/// Ends: when the touch is lifted without moving more than allowableMovement from its starting point.
/// Cancels: when the touch moves too far from its starting point.
class StationaryPressGestureRecognizer: UIGestureRecognizer {

    /// Maximum movement in pixels allowed before the gesture is cancelled. Default is 10.
    var allowableMovement: CGFloat = 10

    /// The initial position on the screen where the press began.
    private var initialTouchPoint: CGPoint?

    convenience init(cancelsTouchesInView: Bool, target: Any?, action: Selector?) {
        self.init(target: target, action: action)

        self.cancelsTouchesInView = cancelsTouchesInView
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        // Only track one touch at a time
        if touches.count == 1 {
            self.state = .began
            self.initialTouchPoint = self.location(in: nil)
        } else {
            self.state = .failed
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard let initialTouchPoint = self.initialTouchPoint else { return }

        // If the user moves their finger too far away from the initial position, cancel the gesture
        let distance = initialTouchPoint.distanceTo(self.location(in: nil))
        if distance > self.allowableMovement {
            self.state = .cancelled
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.state = .cancelled
    }

    override func reset() {
        super.reset()
        self.initialTouchPoint = nil
    }
}
