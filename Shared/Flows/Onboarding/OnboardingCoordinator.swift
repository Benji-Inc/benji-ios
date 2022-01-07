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

    lazy var onboardingVC = OnboardingViewController(with: self)

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }

    override func start() {
        self.setInitialContent()
        self.handle(deeplink: self.deepLink)
    }

    func handle(deeplink: DeepLinkable?) {
        guard let link = deeplink else { return }

        self.onboardingVC.reservationId = link.reservationId
        self.onboardingVC.passId = link.passId
        self.onboardingVC.updateUI()
    }

    private func setInitialContent() {
        guard let current = User.current(), let status = current.status else {
            let welcomeVC = self.onboardingVC.welcomeVC
            self.onboardingVC.switchTo(.welcome(welcomeVC))

            return
        }

        let initialContent: OnboardingContent

        switch status {
        case .active, .waitlist:
            initialContent = .waitlist(self.onboardingVC.waitlistVC)
        case .inactive:
#if APPCLIP
            initialContent = .waitlist(self.onboardingVC.waitlistVC)
#else
            if current.fullName.isEmpty {
                initialContent = .name(self.onboardingVC.nameVC)
            } else if current.smallImage.isNil {
                initialContent = .photo(self.onboardingVC.photoVC)
            } else {
                initialContent = .name(self.onboardingVC.nameVC)
            }
#endif
        case .needsVerification:
            initialContent = .phone(self.onboardingVC.phoneVC)
        }

        self.onboardingVC.switchTo(initialContent)
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
    
    nonisolated func onboardingViewController(_ controller: OnboardingViewController,
                                              didOnboard user: User) {
        Task {
            await controller.showLoading()
            try await ActivateUser().makeRequest(andUpdate: [],
                                                 viewsToIgnore: [controller.view])
            await controller.hideLoading()

            await self.checkForPermissions()
        }
    }

    // MARK: - Permissions Flow

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

