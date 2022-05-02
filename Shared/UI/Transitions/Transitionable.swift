//
//  Transitionable.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol TransitionableViewController where Self: UIViewController & Transitionable { }

protocol Transitionable {

    /// The transition to use when this transitionable is being presented by another transitionable.
    var toVCPresentationType: TransitionType { get }
    /// The transition to use when this transitionable is being dismissed..
    var fromVCDismissalType: TransitionType { get }

    /// The transition to use when this transitionable is presenting another transitionable.
    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType
    /// The transition to use when this transitionable is dismissing another transitionable.
    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType

    /// How long a transition should last.
    var transitionDuration: TimeInterval { get }
}

extension Transitionable {

    var fromVCDismissalType: TransitionType {
        return self.toVCPresentationType
    }

    /// The transition to use when this transitionable is presenting another transitionable.
    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        return toVCPresentationType
    }
    /// The transition to use when this transitionable is dismissing another transitionable.
    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        return fromVCDismissalType
    }

    // Uses the types duration as the default but a controller can also override
    var transitionDuration: TimeInterval {
        return self.toVCPresentationType.duration
    }
}

enum TransitionType: Equatable {
    case move(UIView)
    case fadeOutIn
    case crossDissolve
    case fill(UIView)
    case blur

    #if IOS
    case message(MessageContentView)
    #endif

    var duration: TimeInterval {
        switch self {
        case .move(_):
            return Theme.animationDurationSlow
        case .fadeOutIn:
            return Theme.animationDurationSlow
        case .crossDissolve:
            return Theme.animationDurationFast
        case .fill(_):
            return Theme.animationDurationSlow
        case .blur:
            return Theme.animationDurationSlow
            #if IOS
        case .message(_):
            return Theme.animationDurationSlow
            #endif
        }
    }
}
