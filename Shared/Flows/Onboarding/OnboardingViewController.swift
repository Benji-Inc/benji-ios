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

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingView(_ controller: OnboardingViewController, didVerify user: PFUser)
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
    lazy var ritualVC = RitualInputViewController()
    
    let avatarView = AvatarView()
    private let confettiView = ConfettiView()
    
    unowned let delegate: OnboardingViewControllerDelegate

    var deeplink: DeepLinkable?
    var reservationId: String? {
        didSet {
            self.codeVC.reservationId = self.reservationId
        }
    }
    var reservationUser: User? 
    var reservationCreatorId: String?

    init(with reservationId: String?,
         reservationCreatorId: String?,
         deeplink: DeepLinkable?,
         delegate: OnboardingViewControllerDelegate) {

        self.deeplink = deeplink
        self.reservationId = reservationId
        self.reservationCreatorId = reservationCreatorId
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.scrollView.insertSubview(self.confettiView, aboveSubview: self.blurView)

        self.scrollView.addSubview(self.avatarView)
        self.avatarView.isHidden = true

        self.welcomeVC.$state.mainSink { (state) in
            switch state {
            case .welcome:
                break
            case .signup:
                self.current = .phone(self.phoneVC)
            case .reservationInput:
                break
            case .foundReservation(let reservation):
                self.reservationId = reservation.objectId
                if let identity = reservation.createdBy?.objectId {
                    self.updateReservationCreator(with: identity)
                }
                self.current = .phone(self.phoneVC)
            case .reservationError:
                break
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
                    self.delegate.onboardingView(self, didVerify: current)
                    #endif
                } else if current.status == .inactive, current.isOnboarded {
                    #if APPCLIP
                    self.current = .waitlist(self.waitlistVC)
                    #else
                    self.delegate.onboardingView(self, didVerify: current)
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
                self.current = .ritual(self.ritualVC)
            case .failure(_):
                break
            }
        }

        self.ritualVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success:
                if let user = User.current() {
                    self.delegate.onboardingView(self, didVerify: user)
                }
            case .failure(_):
                break
            }
        }

        self.ritualVC.didTapNeedsAthorization = { [unowned self] in
            self.delegate.onboardingViewControllerNeedsAuthorization(self)
        }

        self.ritualVC.$state.mainSink { state in
            self.updateNavigationBar()
        }.store(in: &self.cancellables)

        self.waitlistVC.$didShowUpgrade.mainSink { [weak self] (didShow) in
            guard let `self` = self, didShow else { return }
            delay(1.0) { [unowned self] in
                self.confettiView.startConfetti(with: 10)
            }
        }.store(in: &self.cancellables)

        if let userId = self.reservationCreatorId {
            self.updateReservationCreator(with: userId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.confettiView.expandToSuperviewSize()

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.pin(.top)
    }

    func updateReservationCreator(with userId: String) {
        User.localThenNetworkQuery(for: userId)
            .mainSink(receiveValue: { (user) in
                self.reservationUser = user
                self.avatarView.set(avatar: user)
                self.avatarView.isHidden = false
                self.updateNavigationBar()
                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }

    override func getInitialContent() -> OnboardingContent {
        guard let status = User.current()?.status else { return .welcome(self.welcomeVC)}
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
            return .name(self.nameVC)
            #endif
        case .needsVerification:
            return .welcome(self.welcomeVC)
        }
    }

    override func getTitle() -> Localized {
        guard let content = self.current else { return "" }
        switch content {
        case .welcome(_):
            return "Welcome!"
        case .phone(_):
            return "Enter Phone"
        case .code(_):
            return "Vefify Code"
        case .name(_):
            return "Add your name"
        case .waitlist(_):
            return "Congrats! 🎉"
        case .photo(let vc):
            switch vc.currentState {
            case .initial:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Verify Indentity")
            case .scan:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Scanning...")
            case .capture:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Identity Verified")
            case .error:
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Error!")
            case .finish:
                return LocalizedString.empty
            }
        case .ritual(let vc):
            switch vc.state {
            case .needsAuthorization:
                return "Last Step"
            case .edit:
                return "DAILY RITUAL"
            case .update:
                return "DAILY RITUAL"
            }
        }
    }

    override func willUpdateContent() {
        super.willUpdateContent()
        guard let current = self.current else { return }
        switch current {
        case .phone(_), .code(_):
            self.avatarView.isHidden = self.reservationUser.isNil
        default:
            self.avatarView.isHidden = true
        }
    }

    override func getDescription() -> Localized {
        super.willUpdateContent()

        guard let content = self.current else { return "" }

        switch content {
        case .welcome(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Ours is an exclusive community of people building a better place to be social online. To best serve this community, we currently require an RSVP for access OR you can tap JOIN to be added to the waitlist.")
        case .phone(_):
            if let user = self.reservationUser {
                return LocalizedString(id: "",
                                       arguments: [user.givenName],
                                       default: "Please verify your mobile number, to accept @(fullname)'s reservation.")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Please verify your account using the mobile number for this device.")
            }
        case .code(_):
            if let user = self.reservationUser {
                return LocalizedString(id: "",
                                       arguments: [user.givenName],
                                       default: "Enter the 4 digit code from the text message, to accept your reservation from @(name).")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "Enter the 4 digit code from the text message.")
            }

        case .name(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "Please use your legal first and last name.")
        case .waitlist(_):
            #if APPCLIP
            if User.current()?.status == .inactive || User.current()?.status == .active {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "You no longer have to wait! Tap the banner below to download the full app.")
            } else {
                return LocalizedString(id: "",
                                       arguments: [],
                                       default: "You are on the list. Sit tight and we will let you know when your slot opens up.")
            }
            #else
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "You are on the list. Sit tight and we will let you know when your slot opens up.")
            #endif

        case .photo(_):
            return LocalizedString(id: "",
                                   arguments: [],
                                   default: "For the safety of yourself and others, we require a front facing photo. This helps ensure everyone is who they say they are. No 🤖's!")
            
        case .ritual(let vc):
            switch vc.state {
            case .needsAuthorization:
                return "A ritual is a period of time each day you are most ready to engage with others. Allow notifications to get started."
            case .edit:
                return "Swipe/tap to set your ritual. Each day, starting at that time, you will have 60 mins to access optimized ways to engage with others."
            case .update:
                return "Your ritual has been set."
            }
        }
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
        switch launchActivity {
        case .onboarding(let phoneNumber):
            if let content = self.current,
               case OnboardingContent.phone(let vc) = content,
               !vc.isSendingCode {
                vc.textField.text = phoneNumber
                vc.textFieldDidEndEditing(vc.textField)
            }
        case .reservation(_):
            break
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
