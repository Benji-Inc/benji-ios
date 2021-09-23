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
    func onboardingView(_ controller: OnboardingViewController, didVerify user: User)
    func onboardingViewControllerNeedsAuthorization(_ controller: OnboardingViewController)
}

class OnboardingViewController: SwitchableContentViewController<OnboardingContent>, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    var transitionColor: Color {
        return .background1
    }

    lazy var welcomeVC = WelcomeViewController()
    lazy var phoneVC = PhoneViewController()
    lazy var codeVC = CodeViewController()
    lazy var nameVC = NameViewController()
    lazy var waitlistVC = WaitlistViewController()
    lazy var photoVC = PhotoViewController()
    lazy var focusVC = FocusStatusViewController()

    let loadingBlur = BlurView()
    let blurEffect = UIBlurEffect(style: .systemMaterial)
    let loadingAnimationView = AnimationView()
    
    private let confettiView = ConfettiView()
    
    unowned let delegate: OnboardingViewControllerDelegate

    var deeplink: DeepLinkable?
    var reservationId: String? {
        didSet {
            self.codeVC.reservationId = self.reservationId
        }
    }
    var reservationOwner: User? 
    var reservationOwnerId: String?

    init(with reservationId: String?,
         reservationCreatorId: String?,
         deeplink: DeepLinkable?,
         delegate: OnboardingViewControllerDelegate) {

        self.deeplink = deeplink
        self.reservationId = reservationId
        self.reservationOwnerId = reservationCreatorId
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

        self.scrollView.insertSubview(self.confettiView, aboveSubview: self.blurView)

        self.welcomeVC.$state.mainSink { (state) in
            switch state {
            case .welcome:
                self.updateUI()
            case .signup:
                self.current = .phone(self.phoneVC)
            case .reservationInput:
                self.updateUI()
            case .foundReservation(let reservation):
                self.reservationId = reservation.objectId
                if let identity = reservation.createdBy?.objectId {
                    self.updateReservationCreator(with: identity)
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
            case .success:
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
            case .success:
                self.handleNameSuccess()
            case .failure(_):
                break
            }
        }

        self.photoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success:
                self.current = .focus(self.focusVC)
            case .failure(_):
                break
            }
        }

        self.focusVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let status):
                if status == .authorized, let user = User.current() {
                    self.delegate.onboardingView(self, didVerify: user)
                }
            case .failure(_):
                break
            }
        }

        self.waitlistVC.$didShowUpgrade.mainSink { [weak self] (didShow) in
            guard let `self` = self, didShow else { return }
            delay(1.0) { [unowned self] in
                self.confettiView.startConfetti(with: 10)
            }
        }.store(in: &self.cancellables)

        if let userId = self.reservationOwnerId {
            self.updateReservationCreator(with: userId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.confettiView.expandToSuperviewSize()
        self.loadingBlur.expandToSuperviewSize()

        self.loadingAnimationView.size = CGSize(width: 18, height: 18)
        self.loadingAnimationView.centerOnXAndY()
    }

    private func showLoading(user: User) {
        self.view.addSubview(self.loadingBlur)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration) {
            self.loadingBlur.effect = self.blurEffect
        } completion: { completed in
            self.loadingAnimationView.play()
            self.delegate.onboardingView(self, didVerify: user)
        }
    }

    func updateReservationCreator(with userId: String) {
        Task {
            guard let user = try? await User.localThenNetworkQuery(for: userId) else { return }

            self.reservationOwner = user
            self.avatarView.set(avatar: user)
            self.avatarView.isHidden = false
            self.updateUI()
            self.view.layoutNow()
        }
    }

    override func getInitialContent() -> OnboardingContent {
        guard let current = User.current(), let status = current.status else { return .welcome(self.welcomeVC)}
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

        self.avatarView.isHidden = self.reservationOwner.isNil
    }

    override func getMessage() -> Localized {
        super.willUpdateContent()
        guard let content = self.current else { return "" }
        return content.getDescription(with: self.reservationOwner)
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
        guard let content = self.current, case OnboardingContent.welcome(let vc) = content else { return }

        switch launchActivity {
        case .onboarding(let phoneNumber):

            self.current = .phone(self.phoneVC)

            delay(0.25) { [unowned self] in
                self.phoneVC.textField.text = phoneNumber
                self.phoneVC.didTapButton()
            }
        case .reservation(let reservationId):
            vc.state = .reservationInput
            vc.textField.text = reservationId

            delay(0.25) {
                vc.didTapButton()
            }
        }
    }

    private func handleNameSuccess() {
        // User has been allowed to continue
        if User.current()?.status == .inactive {
            #if APPCLIP
            self.current = .waitlist(self.waitlistVC)
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
