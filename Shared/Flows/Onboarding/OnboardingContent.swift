//
//  OnboardingContent.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import TMROLocalization

enum OnboardingContent: Switchable {

    case welcome(WelcomeViewController)
    case phone(PhoneViewController)
    case code(CodeViewController)
    case name(NameViewController)
    case waitlist(WaitlistViewController)
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
        case .waitlist(let vc):
            return vc
        case .photo(let vc):
            return vc
        }
    }

    func getDescription(with user: User?) -> Localized {
        switch self {
        case .welcome(let vc):

            switch vc.state {
            case .reservationInput:
                return "Enter the RSVP code, to get immediate access and connect with the person who invited you."
            default:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Jibber is an exclusive community of people building a better place to be social online. To best serve this community, we currently require an RSVP for access OR you can tap JOIN to be added to the waitlist.")
            }
        case .phone(_):
            if let user = user {
                return LocalizedString(id: "",
                                       arguments: [user.fullName],
                                       default: "Please verify your mobile number, to accept @(fullname)'s reservation.")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Please verify your account using the mobile number for this device.")
            }
        case .code(_):
            if let user = user {
                return LocalizedString(id: "",
                                       arguments: [user.givenName],
                                       default: "Enter the 4 digit code from the text message, to accept your reservation from @(name).")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Enter the 4 digit code from the text message.")
            }

        case .name(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Please use your legal first and last name.")
        case .waitlist(_):
            #if APPCLIP
            if User.current()?.status == .inactive || User.current()?.status == .active {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "You no longer have to wait! Tap the banner below to download the full app.")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "You are on the list. Sit tight and we will let you know when your slot opens up.")
            }
            #else
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "You are on the list. Sit tight and we will let you know when your slot opens up.")
            #endif

        case .photo(let vc):
            switch vc.currentState {
            case .initial:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "To ensure everyone is who they say they are we require a photo. No 🤖's!")
            case .scanEyesOpen:
                return ""
            case .scanEyesClosed:
                return ""
            case .captureEyesOpen:
                return ""
            case .captureEyesClosed:
                return ""
            case .error:
                return ""
            case .finish:
                return ""
            }
        }
    }
}
