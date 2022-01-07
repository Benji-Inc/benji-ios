//
//  OnboardingViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Lottie
import Intents
import Localization

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewController(_ controller: OnboardingViewController, didOnboard user: User)
}

class OnboardingViewController: SwitchableContentViewController<OnboardingContent>,
                                TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    lazy var welcomeVC = WelcomeViewController()
    lazy var phoneVC = PhoneViewController()
    lazy var codeVC = CodeViewController()
    lazy var nameVC = NameViewController()
    lazy var waitlistVC = WaitlistViewController()
    lazy var photoVC = PhotoViewController()

    let loadingBlur = BlurView()
    let loadingAnimationView = AnimationView()

    unowned let delegate: OnboardingViewControllerDelegate

    var reservationId: String? {
        didSet {
            self.codeVC.reservationId = self.reservationId
        }
    }

    var passId: String? {
        didSet {
            self.codeVC.passId = self.passId
        }
    }

    var invitor: User?

    init(with delegate: OnboardingViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.loadingAnimationView.load(animation: .loading)
        self.loadingAnimationView.loopMode = .loop
        self.loadingBlur.contentView.addSubview(self.loadingAnimationView)
        
        Task {
            try await self.updateInvitor(with: WelcomeViewController.benjiId)
        }

        self.welcomeVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success:
                self.current = .phone(self.phoneVC)
            case .failure:
                break
            }
        }

        self.phoneVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let phone):
                self.codeVC.phoneNumber = phone
                self.current = .code(self.codeVC)
            case .failure(_):
                break
            }
        }

        self.codeVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let conversationId):
                Task {
                    try await self.saveInitialConversation(with: conversationId)
                }

                guard let current = User.current() else { return }

                switch current.status {
                case .active:
                    self.delegate.onboardingViewController(self, didOnboard: current)
                case .needsVerification, .waitlist, .inactive, .none:
                    self.current = .name(self.nameVC)
                }
            case .failure(_):
                self.current = .waitlist(self.waitlistVC)
            }
        }

        self.nameVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let name):
                self.handleNameSuccess(for: name)
            case .failure(_):
                break
            }
        }

        self.photoVC.$currentState
            .filter({ state in
                return state != .error
            })
            .mainSink { [unowned self] _ in
                self.updateUI()
            }.store(in: &self.cancellables)

        self.photoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success:
                guard let user = User.current() else { return }
                self.delegate.onboardingViewController(self, didOnboard: user)
            case .failure(_):
                break
            }
        }

        self.waitlistVC.$state.mainSink { [unowned self] _ in
            self.updateUI()
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadingBlur.expandToSuperviewSize()

        self.loadingAnimationView.size = CGSize(width: 18, height: 18)
        self.loadingAnimationView.centerOnXAndY()
    }

    // MARK: - Onboarding Step Completion Handling

    private func saveInitialConversation(with conversationId: String?) async throws {
        guard let id = conversationId else { return }
        let object = InitialConveration()
        object.conversationIdString = id
        try await object.saveLocally()
    }

    private func handleNameSuccess(for name: String) {
        Task {
            guard let user = User.current() else { return }
            user.formatName(from: name)
            try await user.saveLocalThenServer()

            switch user.status {
            case .none, .needsVerification:
                self.current = .phone(self.phoneVC)
            case .inactive:
#if APPCLIP
                // The user can't activate their account in an app clip
                self.current = .waitlist(self.waitlistVC)
#else
                if user.isOnboarded {
                    self.delegate.onboardingViewController(self, didOnboard: User.current()!)
                } else {
                    self.current = .photo(self.photoVC)
                }
#endif
            case .waitlist:
                self.current = .waitlist(self.waitlistVC)
            case .active:
                self.delegate.onboardingViewController(self, didOnboard: user)
            }
        }
    }

    // MARK: - SwitchableContentViewController Overrides

    override func shouldShowLargeAvatar() -> Bool {
        switch self.current {
        case .welcome, .phone, .code, .waitlist:
            return true
        case .name, .photo, .none:
            return false
        }
    }

    override func getInitialContent() -> OnboardingContent {
        guard let current = User.current(), let status = current.status else {
            return .welcome(self.welcomeVC)
        }

        switch status {
        case .active, .waitlist:
            return .waitlist(self.waitlistVC)
        case .inactive:
#if APPCLIP
            return .waitlist(self.waitlistVC)
#else
            if current.fullName.isEmpty {
                return .name(self.nameVC)
            } else if current.smallImage.isNil {
                return .photo(self.photoVC)
            } else {
                return .name(self.nameVC)
            }
#endif
        case .needsVerification:
            return .welcome(self.welcomeVC)
        }
    }

    override func willUpdateContent() {
        super.willUpdateContent()

        self.avatarView.isHidden = self.invitor.isNil
    }

    override func didSelectBackButton() {
        super.didSelectBackButton()

        guard let content = self.current else { return }
        switch content {
        case .phone(_):
            self.current = .welcome(self.welcomeVC)
        case .code(_):
            self.current = .phone(self.phoneVC)
        case .photo(_):
            self.current = .name(self.nameVC)
        default:
            break
        }
    }

    override func getMessage() -> Localized? {
        guard let content = self.current else { return nil }
        return content.getDescription(with: self.invitor)
    }

    func handle(launchActivity: LaunchActivity) {
        guard let content = self.current, case OnboardingContent.welcome = content else { return }

        switch launchActivity {
        case .onboarding(let phoneNumber):
            self.current = .phone(self.phoneVC)

            delay(0.25) { [unowned self] in
                self.phoneVC.textField.text = phoneNumber
                self.phoneVC.didTapButton()
            }
        case .reservation(let reservationId):
            self.showLoading()
            Task {
                let reservation = try await Reservation.getObject(with: reservationId)
                self.reservationId = reservationId
                if let userId = reservation.createdBy?.objectId {
                    try await self.updateInvitor(with: userId)
                    await self.hideLoading()
                    self.current = .phone(self.phoneVC)
                }

            }
        case .pass(passId: let passId):
            Task {
                let pass = try await Pass.getObject(with: passId)
                self.passId = passId
                if let userId = pass.owner?.objectId {
                    try await self.updateInvitor(with: userId)
                    await self.hideLoading()
                    self.current = .phone(self.phoneVC)
                }
            }
        }
    }

    @MainActor
    func updateInvitor(with userId: String) async throws {
        let user = try await User.localThenNetworkQuery(for: userId)
        self.invitor = user
        self.avatarView.set(avatar: user)
        self.nameLabel.setText(user.givenName.capitalized)
        self.avatarView.isHidden = false
        self.updateUI()
        self.view.layoutNow()
    }

    // MARK: - Loading Animations

    func showLoading() {
        self.loadingBlur.removeFromSuperview()
        self.view.addSubview(self.loadingBlur)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.loadingBlur.showBlur(true)
        } completion: { completed in
            self.loadingAnimationView.play()
        }
    }

    @MainActor
    func hideLoading() async {
        return await withCheckedContinuation { continuation in
            self.loadingAnimationView.stop()
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.loadingBlur.effect = nil
            } completion: { completed in
                self.loadingBlur.removeFromSuperview()
                continuation.resume(returning: ())
            }
        }
    }

    private func showLoading(user: User) {
        self.loadingBlur.removeFromSuperview()
        self.view.addSubview(self.loadingBlur)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.loadingBlur.showBlur(true)
        } completion: { completed in
            self.loadingAnimationView.play()
            self.delegate.onboardingViewController(self, didOnboard: user)
        }
    }
}
