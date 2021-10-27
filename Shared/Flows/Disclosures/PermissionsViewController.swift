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

class PermissionsViewController: DisclosureModalViewController {

    enum State {
        case focusAsk
        case notificationAsk
        case finished
    }

    @Published var state: State = .focusAsk

    private let focusSwitchView = PermissionSwitchView(with: .focus)

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.focusSwitchView)

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
        self.focusSwitchView.pin(.top)
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

class PermissionSwitchView: View {

    enum PermissionType {
        case focus
        case notificaitons

        var image: UIImage {
            switch self {
            case .focus:
                return UIImage()
            case .notificaitons:
                return UIImage()
            }
        }

        var text: Localized {
            switch self {
            case .focus:
                return "Focus Status"
            case .notificaitons:
                return "Notificaitons"
            }
        }
    }

    let type: PermissionType
    private let imageView = DisplayableImageView()
    private let label = Label(font: .small)
    private(set) var  switchView = UISwitch()

    init(with type: PermissionType) {
        self.type = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.displayable = self.type.image
        self.addSubview(self.label)
        self.label.setText(self.type.text)
        self.addSubview(self.switchView)

        self.layer.borderColor = Color.white.color.cgColor
        self.layer.borderWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.roundCorners()

        self.imageView.squaredSize = self.height - Theme.contentOffset
        self.imageView.pin(.left, padding: Theme.contentOffset.half)
        self.imageView.centerOnY()

        self.label.setSize(withWidth: self.width)
        self.label.match(.left, to: .right, of: self.imageView, offset: Theme.contentOffset.half)
        self.label.centerOnY()

        self.switchView.centerOnY()
        self.switchView.pin(.right, padding: Theme.contentOffset.half)
    }
}
