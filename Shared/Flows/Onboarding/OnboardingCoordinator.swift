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

    private lazy var onboardingVC = OnboardingViewController(with: self)

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }

    override func start() {
        self.setInitialOnboardingContent()
        self.handle(deeplink: self.deepLink)
    }

    func handle(deeplink: DeepLinkable?) {
        guard let link = deeplink else { return }

        self.onboardingVC.reservationId = link.reservationId ?? ""
        self.onboardingVC.passId = link.passId ?? ""
        self.onboardingVC.updateUI()
    }

    // MARK: - Onboarding Flow Logic

    private func setInitialOnboardingContent() {
        let userStatus = User.current()?.status

        let initialContent: OnboardingContent
        switch userStatus {
        case .needsVerification, .inactive, .waitlist, .none:
            initialContent = .welcome(self.onboardingVC.welcomeVC)
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
        case .inactive:
            if !current.fullName.isValidFullName {
                return .name(self.onboardingVC.nameVC)
            } else if current.smallImage.isNil {
                #if targetEnvironment(simulator)
                return nil
                #else
                return .photo(self.onboardingVC.photoVC)
                #endif
            } else {
                return nil
            }
        case .active, .waitlist:
            // Active users don't need to do onboarding.
            return nil
        }
    }
}

extension OnboardingCoordinator: OnboardingViewControllerDelegate {

    // MARK: - User Info Entry Flow

    func onboardingViewControllerDidStartOnboarding(_ controller: OnboardingViewController) {
        let phoneVC = self.onboardingVC.phoneVC
        self.onboardingVC.switchTo(.phone(phoneVC))
    }
    
    func onboardingViewControllerDidSelectRSVP(_ controller: OnboardingViewController) {

        let alertController = UIAlertController(title: "RSVP",
                                                message: "Please enter the code you received.",
                                                preferredStyle: .alert)
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Code"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {
                controller.handle(launchActivity: .reservation(reservationId: text))
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        controller.present(alertController, animated: true, completion: nil)
    }

    func onboardingViewController(_ controller: OnboardingViewController, didEnter phoneNumber: PhoneNumber) {
        let codeVC = self.onboardingVC.codeVC
        codeVC.phoneNumber = phoneNumber
        self.onboardingVC.switchTo(.code(codeVC))
    }

    func onboardingViewControllerDidVerifyCode(_ controller: OnboardingViewController,
                                               andReturnCID cid: String?) {
        self.goToNextContentOrFinish()
    }

    func onboardingViewController(_ controller: OnboardingViewController, didEnterName name: String) {
        Task {
            do {
                guard let user = User.current() else { return }
                user.formatName(from: name)
                try await user.saveLocalThenServer()

                self.goToNextContentOrFinish()
            } catch  {
                logError(error)
            }
        }
    }

    func onboardingViewControllerDidTakePhoto(_ controller: OnboardingViewController) {
        self.goToNextContentOrFinish()
    }

    private func goToNextContentOrFinish() {
        if let nextContent = self.getNextIncompleteOnboardingContent() {
            self.onboardingVC.switchTo(nextContent)
        } else if let user = User.current() {
            switch user.status {
            case .needsVerification, .none, .active:
                self.finishFlow(with: ())
            case .inactive, .waitlist:
                self.finalizeOnboarding(user: user)
            }
        }
    }
    
    func finalizeOnboarding(user: User) {
        Task {
            self.onboardingVC.showLoading()
            if await !self.hasNeededPermissions() {
                await self.presentPermissions()
            }
            do {
                try await FinalizeOnboarding(reservationId: self.onboardingVC.reservationId,
                                             passId: self.onboardingVC.passId).makeRequest(andUpdate: [],
                                                                                           viewsToIgnore: [self.onboardingVC.view])
            } catch {
                logError(error)
            }
            
            AnalyticsManager.shared.trackEvent(type: .finalizedOnboarding, properties: ["status": user.status?.rawValue ?? ""])
            await self.onboardingVC.hideLoading()
            self.finishFlow(with: ())
        }
    }

    // MARK: - Permissions Flow

    @MainActor
    private func hasNeededPermissions() async -> Bool {
        #if IOS
        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            return false
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            return false
        } else {
            return true
        }
        #else
        // No need to check permissions for AppClip
        return true
        #endif
    }

    @MainActor
    private func presentPermissions() async {
        return await withCheckedContinuation { continuation in
            let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
            
            coordinator.toPresentable().dismissHandlers.append {
                continuation.resume(returning: ())
            }
            
            self.addChildAndStart(coordinator) { [unowned self] result in
                self.router.dismiss(source: self.onboardingVC, animated: true)
            }
            
            self.router.present(coordinator, source: self.onboardingVC)
        }
    }
}

// MARK: - Launch Activity Handling

extension OnboardingCoordinator: LaunchActivityHandler {

    nonisolated func handle(launchActivity: LaunchActivity) {
        Task.onMainActor {
            self.onboardingVC.handle(launchActivity: launchActivity)
        }
    }
}
