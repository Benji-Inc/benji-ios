//
//  OnboardingContent.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Localization

enum OnboardingContent: Switchable {

    case welcome(WelcomeViewController)
    case phone(PhoneViewController)
    case code(CodeViewController)
    case name(NameViewController)
    case photo(PhotoViewController)

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
        case .photo(let vc):
            return vc
        }
    }

    func getDescription(with user: User?) -> Localized? {
        switch self {
        case .welcome(_):
            return nil
        case .phone(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Confirm your mobile so we can chat")
        case .code(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Enter the code Jibber texted you")
        case .name(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Confirm your name to use Jibber!")
        case .photo(let vc):
            switch vc.currentState {
            case .initial:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Tap the screen so I can see you 😀")
            case .scanEyesOpen:
                return "Now smile and tap the screen."
            case .didCaptureEyesOpen:
                return "Good one!"
            case .captureEyesOpen:
                return "Try again"
            case .error:
                return ""
            case .finish:
                return "Now turn these on."
            }
        }
    }
}
