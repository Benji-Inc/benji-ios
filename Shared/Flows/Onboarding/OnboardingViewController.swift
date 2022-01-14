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
import PhoneNumberKit

@MainActor
protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerDidStartOnboarding(_ controller: OnboardingViewController)
    func onboardingViewControllerDidSelectRSVP(_ controller: OnboardingViewController)
    func onboardingViewController(_ controller: OnboardingViewController, didEnter phoneNumber: PhoneNumber)
    func onboardingViewControllerDidVerifyCode(_ controller: OnboardingViewController,
                                               andReturnCID conversationId: String?)
    func onboardingViewController(_ controller: OnboardingViewController, didEnterName name: String)
    func onboardingViewControllerDidTakePhoto(_ controller: OnboardingViewController)
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
        
        
        
        self.welcomeVC.didLoadConversation = { [unowned self] conversation in
            Task {
                try await self.updateInvitor(userId: conversation.authorId)
            }
        }

        self.welcomeVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let selection):
                switch selection {
                case .waitlist:
                    self.delegate.onboardingViewControllerDidStartOnboarding(self)
                case .rsvp:
                    self.delegate.onboardingViewControllerDidSelectRSVP(self)
                }
            case .failure:
                break
            }
        }

        self.phoneVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let phone):
                self.delegate.onboardingViewController(self, didEnter: phone)
            case .failure(_):
                break
            }
        }

        self.codeVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let conversationId):
                self.delegate.onboardingViewControllerDidVerifyCode(self,
                                                                    andReturnCID: conversationId)
            case .failure(_):
                break
            }
        }

        self.nameVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let name):
                self.delegate.onboardingViewController(self, didEnterName: name)
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
                self.delegate.onboardingViewControllerDidTakePhoto(self)
            case .failure(_):
                break
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadingBlur.expandToSuperviewSize()

        self.loadingAnimationView.size = CGSize(width: 18, height: 18)
        self.loadingAnimationView.centerOnXAndY()
    }

    // MARK: - SwitchableContentViewController Overrides

    override func shouldShowLargeAvatar() -> Bool {
        switch self.currentContent {
        case .welcome, .phone, .code:
            return true
        case .name, .photo, .none:
            return false
        }
    }

    override func willUpdateContent() {
        super.willUpdateContent()

        self.avatarView.isHidden = self.invitor.isNil
    }

    override func didSelectBackButton() {
        super.didSelectBackButton()

        guard let content = self.currentContent else { return }
        switch content {
        case .phone(_):
            self.switchTo(.welcome(self.welcomeVC))
        case .code(_):
            self.switchTo(.phone(self.phoneVC))
        case .photo(_):
            self.switchTo(.name(self.nameVC))
        default:
            break
        }
    }

    override func getMessage() -> Localized? {
        guard let content = self.currentContent else { return nil }
        return content.getDescription(with: self.invitor)
    }

    func handle(launchActivity: LaunchActivity) {
        guard let content = self.currentContent, case OnboardingContent.welcome = content else { return }

        switch launchActivity {
        case .onboarding(let phoneNumber):
            self.switchTo(.phone(self.phoneVC))

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
                    try await self.updateInvitor(userId: userId)
                    await self.hideLoading()
                    self.switchTo(.phone(self.phoneVC))
                }

            }
        case .pass(passId: let passId):
            Task {
                let pass = try await Pass.getObject(with: passId)
                self.passId = passId
                if let userId = pass.owner?.objectId {
                    try await self.updateInvitor(userId: userId)
                    await self.hideLoading()
                    self.switchTo(.phone(self.phoneVC))
                }
            }
        }
    }

    @MainActor
    func updateInvitor(userId: String) async throws {
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
}
