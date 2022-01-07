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
        guard let status = User.current()?.status else {
            // If there is no user, then they'll need to provide a phone number to create one.
            let welcomeVC = self.onboardingVC.welcomeVC
            self.onboardingVC.switchTo(.welcome(welcomeVC))
            return
        }

        let initialContent: OnboardingContent
        switch status {
        case .needsVerification:
            initialContent = .welcome(self.onboardingVC.welcomeVC)
        case .inactive, .waitlist:
            if let nextContent = self.getNextIncompleteOnboardingContent() {
                initialContent = nextContent
            } else {
                initialContent = .welcome(self.onboardingVC.welcomeVC)
            }
        case .active:
            self.finishFlow(with: ())
            return
        }

        self.onboardingVC.switchTo(initialContent)
    }

    /// Returns the content for the first incompleted onboarding step in the onboarding sequence.
    private func getNextIncompleteOnboardingContent() -> OnboardingContent? {
        guard let current = User.current(), let status = current.status else {
            // If there is no user, then they'll need to provide a phone number to create one.
            return .phone(self.onboardingVC.phoneVC)
        }

        switch status {
        case .needsVerification:
            return .code(self.onboardingVC.codeVC)
        case .waitlist:
            if current.fullName.isEmpty {
                return .name(self.onboardingVC.nameVC)
            } else if current.smallImage.isNil {
                return .photo(self.onboardingVC.photoVC)
            } else {
                return .waitlist(self.onboardingVC.waitlistVC)
            }
        case .inactive:
            if current.fullName.isEmpty {
                return .name(self.onboardingVC.nameVC)
            } else if current.smallImage.isNil {
                return .photo(self.onboardingVC.photoVC)
            } else {
                return nil
            }
        case .active:
            // Active users don't need to do onboarding.
            return nil
        }
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

