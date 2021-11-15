//
//  OnboardingViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization
import Lottie
import Intents

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingView(_ controller: OnboardingViewController,
                        didVerify user: User)
}

class OnboardingViewController: SwitchableContentViewController<OnboardingContent>, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    var transitionColor: Color {
        return .background
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

        self.welcomeVC.$state.mainSink { (state) in
            switch state {
            case .welcome:
                self.updateUI()
            case .login:
                Task {
                    try await self.updateInvitor(with: "IQgIBSPHpE")
                }
                self.current = .phone(self.phoneVC)
            case .reservationInput:
                self.updateUI()
            case .foundReservation(let reservation):
                self.reservationId = reservation.objectId
                if let identity = reservation.createdBy?.objectId {
                    Task {
                        try await self.updateInvitor(with: identity)
                    }
                }
                self.current = .phone(self.phoneVC)
            case .reservationError:
                self.updateUI()
            }
        }.store(in: &self.cancellables)

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
                if current.isOnboarded, current.status == .active {
                    #if APPCLIP
                    self.current = .waitlist(self.waitlistVC)
                    #else
                    self.showLoading(user: current)
                    #endif
                } else if current.status == .inactive, current.isOnboarded {
                    #if APPCLIP
                    self.current = .waitlist(self.waitlistVC)
                    #else
                    self.showLoading(user: current)
                    #endif
                } else {
                    self.current = .name(self.nameVC)
                }
            case .failure(_):
                break
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
                Task {
                    guard let fullName = UserDefaultsManager.getString(for: .fullName) else { return }
                    try await ActivateUser(fullName: fullName).makeRequest(andUpdate: [], viewsToIgnore: [self.view])
                    guard let user = User.current(), user.status == .active else { return }
                    self.delegate.onboardingView(self, didVerify: user)
                }
            case .failure(_):
                break
            }
        }

        self.waitlistVC.$state.mainSink { [unowned self] _ in
            self.updateUI()
        }.store(in: &self.cancellables)
    }

    private func saveInitialConversation(with conversationId: String?) async throws {
        guard let id = conversationId else { return }
        let object = InitialConveration()
        object.conversationId = id
        try await object.saveLocally()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadingBlur.expandToSuperviewSize()

        self.loadingAnimationView.size = CGSize(width: 18, height: 18)
        self.loadingAnimationView.centerOnXAndY()
    }

    override func shouldShowLargeAvatar() -> Bool {
        guard let current = self.current else { return false }
        switch current {
        case .welcome(_):
            return true
        case .phone(_):
            return true
        case .code(_):
            return true
        case .name(_):
            return false
        case .waitlist(_):
            return true
        case .photo(_):
            return false
        }
    }

    private func showLoading() {
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
    private func hideLoading() async {
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
            self.delegate.onboardingView(self, didVerify: user)
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

    override func getInitialContent() -> OnboardingContent {
        guard let current = User.current(), let status = current.status else { return .welcome(self.welcomeVC) }

        switch status {
        case .active, .waitlist:
            #if APPCLIP
            return .waitlist(self.waitlistVC)
            #else
            fatalError()
            #endif
        case .inactive:
            #if APPCLIP
            return .waitlist(self.waitlistVC)
            #else
            if current.fullName.isEmpty {
                return .name(self.nameVC)
            } else if current.smallImage.isNil || current.focusImage.isNil {
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

    override func getMessage() -> Localized? {
        guard let content = self.current else { return nil }
        return content.getDescription(with: self.invitor)
    }

    override func didSelectBackButton() {
        super.willUpdateContent()

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

    func handle(launchActivity: LaunchActivity) {
        guard let content = self.current, case OnboardingContent.welcome(_) = content else { return }

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

    private func handleNameSuccess(for name: String) {
        UserDefaultsManager.update(key: .fullName, with: name)
        // User has been allowed to continue
        if User.current()?.status == .inactive {
            #if APPCLIP
            Task {
                User.current()?.formatName(from: name)
                try await User.current()?.saveLocalThenServer()
                self.current = .waitlist(self.waitlistVC)
            }
            #else
            if let current = User.current(), current.isOnboarded {
                self.delegate.onboardingView(self, didVerify: User.current()!)
            } else {
                self.current = .photo(self.photoVC)
            }
            #endif
        } else {
            // User is on the waitlist
            self.current = .waitlist(self.waitlistVC)
        }
    }
}
