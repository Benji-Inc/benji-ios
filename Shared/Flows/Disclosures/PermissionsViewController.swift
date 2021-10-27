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

        var title: Localized {
            switch self {
            case .focusAsk:
                return "Focus Status"
            case .notificationAsk:
                return "Notifications"
            case .finished:
                return "Success!"
            }
        }

        var description: HightlightedPhrase {
            switch self {
            case .focusAsk:
                return HightlightedPhrase(text: "Changing Focus status updates your picture so people see if you are available or busy.",
                                          highlightedWords: ["Focus"])
            case .notificationAsk:
                return HightlightedPhrase(text: "Allowing Notifications means you never miss out on what’s important. No noise.",
                                          highlightedWords: ["Notifications"])
            case .finished:
                return HightlightedPhrase(text: "Now that you have Focus status and Notifications on, you are ready to Jibber!",
                                          highlightedWords: ["Focus", "Notifications"])
            }
        }
    }

    @Published var state: State = .focusAsk

    private let focusSwitchView = PermissionSwitchView(with: .focus)
    private let notificationSwitchView = PermissionSwitchView(with: .notificaitons)
    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.focusSwitchView)

        self.focusSwitchView.switchView.addAction(UIAction(handler: { action in
            self.handleFocus(isON: self.focusSwitchView.isON)
        }), for: .valueChanged)

        #if !APPCLIP && !NOTIFICATION
        self.contentView.addSubview(self.notificationSwitchView)
        self.notificationSwitchView.switchView.addAction(UIAction(handler: { action in
            self.handleNotifications(isON: self.notificationSwitchView.isON)
        }), for: .valueChanged)
        #endif

        self.contentView.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: "Done"))
        self.button.isUserInteractionEnabled = false
        self.button.alpha = 0.25

        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
            self.updateUI(for: state)
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.expandToSuperviewWidth()
        self.button.height = Theme.buttonHeight
        self.button.pin(.bottom, padding: Theme.contentOffset)

        self.notificationSwitchView.expandToSuperviewWidth()
        self.notificationSwitchView.height = Theme.buttonHeight
        self.notificationSwitchView.match(.bottom, to: .top, of: self.button, offset: -Theme.contentOffset.half)

        self.focusSwitchView.expandToSuperviewWidth()
        self.focusSwitchView.height = Theme.buttonHeight
        self.focusSwitchView.match(.bottom, to: .top, of: self.notificationSwitchView, offset: -Theme.contentOffset.half)
    }

    private func updateUI(for state: State) {

        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
        } completion: { completed in
            self.titleLabel.setText(state.title)
            self.updateDescription(with: state.description)

            UIView.animate(withDuration: 0.2) {
                self.titleLabel.alpha = 1.0
                self.descriptionLabel.alpha = 1.0
            } completion: { _ in
                if state == .focusAsk {
                    Task {
                        await self.layoutSwitches()
                    }
                } else if state == .finished {
                    self.focusSwitchView.state = .hidden
                    self.notificationSwitchView.state = .hidden

                    self.button.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.2) {
                        self.button.alpha = 1.0
                    }
                }
            }
        }
    }

    @MainActor
    private func layoutSwitches() async {

        switch INFocusStatusCenter.default.authorizationStatus {
        case .notDetermined:
            self.focusSwitchView.state = .enabled
            self.focusSwitchView.switchView.setOn(false, animated: true)
        case .restricted, .denied:
            self.focusSwitchView.state = .disabled
            self.focusSwitchView.switchView.setOn(false, animated: true)
        case .authorized:
            self.focusSwitchView.state = .disabled
            self.focusSwitchView.switchView.setOn(true, animated: true)
        @unknown default:
            break
        }

        if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.notificationSwitchView.state = .disabled
        } else {
            self.notificationSwitchView.state = .enabled
            self.notificationSwitchView.switchView.setOn(true, animated: true)
        }
    }

    private func handleFocus(isON: Bool) {
        if isON, INFocusStatusCenter.default.authorizationStatus == .notDetermined {
            /// Request authorization to check Focus Status
            INFocusStatusCenter.default.requestAuthorization { status in
                /// Provides a INFocusStatusAuthorizationStatus
                if status != .authorized {
                    self.focusSwitchView.switchView.setOn(false, animated: true)
                } else {
                    Task {
                        if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
                            self.state = .notificationAsk
                            self.notificationSwitchView.state = .enabled
                        }
                    }
                }
            }
        }
    }

    #if !APPCLIP && !NOTIFICATION
    private func handleNotifications(isON: Bool) {
        Task {
            if await UserNotificationManager.shared.register(application: UIApplication.shared) {
                self.state = .finished
            } else {
                self.notificationSwitchView.switchView.setOn(false, animated: true)
            }
        }
    }
    #endif
}
