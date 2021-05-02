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

    override func handle(launchActivity: LaunchActivity) {
        super.handle(launchActivity: launchActivity)

        self.onboardingVC.handle(launchActivity: launchActivity)
    }
}

extension OnboardingCoordinator: OnboardingViewControllerDelegate {
    func onboardingView(_ controller: OnboardingViewController, didVerify user: PFUser) {
        self.finishFlow(with: ())
    }

    func onboardingViewControllerNeedsAuthorization(_ controller: OnboardingViewController) {
        #if !NOTIFICATION
        UserNotificationManager.shared.register(application: UIApplication.shared)
            .mainSink { (granted) in
                if granted {
                    controller.ritualVC.state = .update
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                }
            }.store(in: &self.cancellables)
        #endif
    }
}

