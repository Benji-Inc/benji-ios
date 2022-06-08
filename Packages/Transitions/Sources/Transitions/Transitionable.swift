//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

public protocol Transitionable {
    
    /// The transition to use when this transitionable is being presented by another transitionable.
    var presentationType: TransitionType { get }
    /// The transition to use when this transitionable is being dismissed..
    var dismissalType: TransitionType { get }

    /// The transition to use when this transitionable is presenting another  with the given transition type.
    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType
    /// The transition to use when this transitionable is dismissing another transitionable of the given type.
    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType
}

public extension Transitionable {
    
    var presentationType: TransitionType {
        return .fadeOutIn
    }

    var dismissalType: TransitionType {
        return self.presentationType
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        return fromVCDismissalType
    }
}
