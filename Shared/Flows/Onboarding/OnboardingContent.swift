//
//  OnboardingContent.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum OnboardingContent: Switchable {

    case welcome(WelcomeViewController)
    case phone(PhoneViewController)
    case code(CodeViewController)
    case name(NameViewController)
    case waitlist(WaitlistViewController)
    case photo(PhotoViewController)
    case focus(FocusStatusViewController)

    var viewController: UIViewController & Sizeable {
        switch self {
        case .welcome(let vc):
            return vc
        case .phone(let vc):
            return vc
        case .code(let vc):
            return vc
        case .name(let vc):
            return vc
        case .waitlist(let vc):
            return vc
        case .photo(let vc):
            return vc
        case .focus(let vc)
        }
    }

    var shouldShowBackButton: Bool {
        switch self {
        case .welcome(_):
            return false
        case .phone(_):
            return true 
        case .code(_):
            return true
        case .name(_):
            return false
        case .waitlist(_):
            return false 
        case .photo(_):
            return true
        case .focus(_):
            return false 
        }
    }
}
