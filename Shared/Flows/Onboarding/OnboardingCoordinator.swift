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
import Combine
import Intents

class OnboardingCoordinator: PresentableCoordinator<Void> {

    lazy var onboardingVC = OnboardingViewController(with: self.reservationId,
                                                     reservationCreatorId: self.reservationCreatorId,
                                                     passId: self.passId,
                                                     deeplink: self.deepLink,
                                                     delegate: self)
    let reservationId: String?
    let reservationCreatorId: String?
    let passId: String?

    init(reservationId: String?,
         reservationCreatorId: String?,
         passId: String?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.passId = passId
        self.reservationId = reservationId
        self.reservationCreatorId = reservationCreatorId ?? "IQgIBSPHpE"

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }

    func handle(deeplink: DeepLinkable?) {
        guard let link = deeplink else { return }
        self.onboardingVC.deeplink = link
        self.onboardingVC.reservationId = link.reservationId
        self.onboardingVC.reservationOwnerId = link.reservationCreatorId
        self.onboardingVC.updateUI()
    }
}

extension OnboardingCoordinator: LaunchActivityHandler {

    nonisolated func handle(launchActivity: LaunchActivity) {
        Task.onMainActor {
            self.onboardingVC.handle(launchActivity: launchActivity)
        }
    }
}

extension OnboardingCoordinator: OnboardingViewControllerDelegate {
    
    nonisolated func onboardingView(_ controller: OnboardingViewController, didVerify user: User) {
        Task {
            await self.checkForPermissions()
        }
    }

    @MainActor
    private func checkForPermissions() async {
        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            self.presentPermissions()
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.presentPermissions()
        } else {
            self.router.dismiss(source: self.onboardingVC, animated: true) {
                self.finishFlow(with: ())
            }
        }
    }

    @MainActor
    private func presentPermissions() {
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: self.onboardingVC, animated: true) {
                self.finishFlow(with: ())
            }
        }
        self.router.present(coordinator, source: self.onboardingVC)
    }
}

