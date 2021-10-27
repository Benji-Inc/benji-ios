//
//  PermissionsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import TMROLocalization
import Combine

class PermissionsViewController: DisclosureModalViewController {

    enum State {
        case focusAsk
        case notificationAsk
        case finished
    }

    @Published var state: State = .focusAsk

    private let focusSwitchView = PermissionSwitchView(with: .focus)
    private let notificationSwitchView = PermissionSwitchView(with: .notificaitons)

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.focusSwitchView)

        self.focusSwitchView.switchView.addAction(UIAction(handler: { action in
            self.handleFocus(isON: self.focusSwitchView.isON)
        }), for: .valueChanged)

        self.contentView.addSubview(self.notificationSwitchView)
        self.notificationSwitchView.switchView.addAction(UIAction(handler: { action in
            self.handleNotifications(isON: self.notificationSwitchView.isON)
        }), for: .valueChanged)

        self.$state.mainSink { [unowned self] state in
            self.updateUI(for: state)
        }.store(in: &self.cancellables)

        Task {
            await self.determineInitialState()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.focusSwitchView.expandToSuperviewWidth()
        self.focusSwitchView.height = 60
        self.focusSwitchView.pin(.top, padding: Theme.contentOffset)

        self.notificationSwitchView.expandToSuperviewWidth()
        self.notificationSwitchView.height = 60
        self.notificationSwitchView.match(.top, to: .bottom, of: self.focusSwitchView, offset: Theme.contentOffset.half)
    }

    @MainActor
    private func determineInitialState() async {

        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            self.state = .focusAsk
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.state = .notificationAsk
        }
//        /// Request authorization to check Focus Status
//        INFocusStatusCenter.default.requestAuthorization { status in
//            /// Provides a INFocusStatusAuthorizationStatus
//        }
//
//        Task {
//            await UserNotificationManager.shared.register(application: UIApplication.shared)
//        }
    }

    private func updateUI(for state: State) {
        switch state {
        case .focusAsk:
            break
        case .notificationAsk:
            break
        case .finished:
            break 
        }

        self.view.layoutNow()
    }

    private func handleFocus(isON: Bool) {
        print("Focus isON \(isON)")
    }

    private func handleNotifications(isON: Bool) {
        print("Notificaiton isON \(isON)")
    }
}
