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

class OnboardingCoordinator: PresentableCoordinator<String?> {

    lazy var onboardingVC = OnboardingViewController(with: self)
    private var conversationId: String?

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }

    override func start() {
        self.handle(deeplink: self.deepLink)
    }

    func handle(deeplink: DeepLinkable?) {
        guard let link = deeplink else { return }
        self.onboardingVC.reservationId = link.reservationId
        self.onboardingVC.passId = link.passId
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
    
    nonisolated func onboardingView(_ controller: OnboardingViewController,
                                    didVerify user: User,
                                    conversationId: String?) {
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
                self.finishFlow(with: (self.conversationId))
            }
        }
    }

    @MainActor
    private func presentPermissions() {
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: self.onboardingVC, animated: true) {
                self.finishFlow(with: (self.conversationId))
            }
        }
        self.router.present(coordinator, source: self.onboardingVC)
    }
}

