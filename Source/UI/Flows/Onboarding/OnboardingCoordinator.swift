//
//  LoginCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit
import Parse

class OnboardingCoordinator: PresentableCoordinator<Void> {

    lazy var onboardingVC = OnboardingViewController(with: self.reservation, deeplink: self.deepLink, delegate: self)
    let reservation: Reservation?

    init(reservation: Reservation?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.reservation = reservation

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }
}

extension OnboardingCoordinator: OnboardingViewControllerDelegate {
    func onboardingView(_ controller: OnboardingViewController, didVerify user: PFUser) {
        self.finishFlow(with: ())
    }
}
