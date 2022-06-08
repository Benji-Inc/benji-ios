//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

public enum TransitionType {

    case move(view: UIView)
    case fadeOutIn
    case crossDissolve
    case fill(view: UIView, color: UIColor)
    case modal
    case custom(type: String, model: Any?, duration: TimeInterval)
}
