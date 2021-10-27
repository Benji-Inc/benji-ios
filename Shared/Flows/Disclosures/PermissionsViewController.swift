//
//  PermissionsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

class PermissionsViewController: DisclosureModalViewController {

    enum State {
        case focusAsk
        case notificationAsk
        case finished
    }

    @Published var state: State = .focusAsk

    override func initializeViews() {
        super.initializeViews()

        self.$state.mainSink { [unowned self] state in
            self.updateUI(for: state)
        }.store(in: &self.cancellables)

        Task {
            await self.determineInitialState()
        }
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
}
