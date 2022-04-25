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
    var sendingPresentationType: TransitionType { get }
    var sendingDismissalType: TransitionType { get }
    var receivingPresentationType: TransitionType { get }
    var receivingDismissalType: TransitionType { get }
    var transitionDuration: TimeInterval { get }

    func getTransitionType(for operation: UINavigationController.Operation, isFromVC: Bool) -> TransitionType
}

extension Transitionable {

    var sendingPresentationType: TransitionType {
        return .fade
    }

    var sendingDismissalType: TransitionType {
        return .fade
    }

    var receivingDismissalType: TransitionType {
        return .fade
    }

    // Uses the types duration as the default but a controller can also override
    var transitionDuration: TimeInterval {
        return self.receivingPresentationType.duration
    }

    func getTransitionType(for operation: UINavigationController.Operation, isFromVC: Bool) -> TransitionType {
        switch operation {
        case .none:
            return isFromVC ? self.sendingPresentationType : self.receivingPresentationType
        case .push:
            return isFromVC ? self.sendingPresentationType : self.receivingPresentationType
        case .pop:
            return isFromVC ? self.sendingDismissalType : self.receivingDismissalType
        @unknown default:
            return self.receivingPresentationType
        }
    }
}

enum TransitionType: Equatable {
    case move(UIView)
    case fade
    case fill(UIView)
    #if IOS
    case message(MessageContentView)
    #endif

    var duration: TimeInterval {
        switch self {
        case .move(_):
            return Theme.animationDurationSlow
        case .fade:
            return Theme.animationDurationSlow
        case .fill(_):
            return Theme.animationDurationSlow
            #if IOS
        case .message(_):
            return Theme.animationDurationSlow
            #endif
        }
    }
}
