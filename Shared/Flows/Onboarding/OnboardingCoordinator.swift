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

class OnboardingCoordinator: PresentableCoordinator<Void> {

    private var cancellables = Set<AnyCancellable>()

    lazy var onboardingVC = OnboardingViewController(with: self.reservationId,
                                                     reservationCreatorId: self.reservationCreatorId,
                                                     deeplink: self.deepLink,
                                                     delegate: self)
    let reservationId: String?
    let reservationCreatorId: String?

    init(reservationId: String?,
         reservationCreatorId: String?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.reservationId = reservationId
        self.reservationCreatorId = reservationCreatorId

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.onboardingVC
    }

    func handle(deeplink: DeepLinkable?) {
        guard let link = deeplink else { return }
        self.onboardingVC.deeplink = link
        self.onboardingVC.reservationId = link.reservationId
        self.onboardingVC.reservationCreatorId = link.reservationCreatorId
        self.onboardingVC.updateNavigationBar()
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

    nonisolated func onboardingView(_ controller: OnboardingViewController, didVerify user: PFUser) {
        Task {
            await self.finishFlow(with: ())
        }
    }

    nonisolated func onboardingViewControllerNeedsAuthorization(_ controller: OnboardingViewController) {
#if !NOTIFICATION
        Task {
            await self.checkForNotifications()
        }
#endif
    }

#if !NOTIFICATION
    private func checkForNotifications() async {
        let settings = await UserNotificationManager.shared.getNotificationSettings()

        if settings.authorizationStatus != .authorized {
            await self.showSoftAskNotifications(for: settings.authorizationStatus)
        }
    }

    private func showSoftAskNotifications(for status: UNAuthorizationStatus) async {
        let alert = UIAlertController(title: "Notifications that don't suck.",
                                      message: "Most other social apps design their notifications to be vague in order to suck you in for as long as possible. Ours are not. Get reminders about things that YOU set, and recieve important messages from REAL people. Ours is a far better experience with them turned on.",
                                      preferredStyle: .alert)

        let allow = UIAlertAction(title: "Allow", style: .default) { action in
            if status == .denied {
                if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
                    if UIApplication.shared.canOpenURL(appSettings) {
                        UIApplication.shared.open(appSettings)
                    }
                }
            } else {
                Task {
                    await UserNotificationManager.shared.register(application: UIApplication.shared)
                }
            }
        }

        let cancel = UIAlertAction(title: "Maybe Later", style: .cancel) { action in}

        alert.addAction(cancel)
        alert.addAction(allow)

        self.router.topmostViewController.present(alert, animated: true, completion: nil)
    }
#endif
}

