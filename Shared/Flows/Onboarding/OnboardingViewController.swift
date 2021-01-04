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

protocol OnboardingViewControllerDelegate: class {
    func onboardingView(_ controller: OnboardingViewController, didVerify user: PFUser)
}

class OnboardingViewController: SwitchableContentViewController<OnboardingContent> {

    lazy var phoneVC = PhoneViewController(with: self.reservationId, reservationCreatorId: self.reservationCreatorId)
    lazy var codeVC = CodeViewController(with: self.reservationId)
    lazy var nameVC = NameViewController()
    lazy var waitlistVC = WaitlistViewController()
    lazy var photoVC = PhotoViewController()
    let avatarView = AvatarView()
    
    unowned let delegate: OnboardingViewControllerDelegate

    var deeplink: DeepLinkable?
    var reservationId: String?
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

        self.registerKeyboardEvents()

        self.scrollView.addSubview(self.avatarView)
        self.avatarView.isHidden = true 

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
                if let current = User.current(), current.isOnboarded, current.status == .active {
                    #if !APPCLIP
                    // Code you don't want to use in your App Clip.
                    self.delegate.onboardingView(self, didVerify: current)
                    #else
                    // Code your App Clip may access.
                    self.current = .waitlist(self.waitlistVC)
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
                if let user = User.current() {
                    self.delegate.onboardingView(self, didVerify: user)
                }
            case .failure(_):
                break
            }
        }

        if let userId = self.reservationCreatorId {
            self.updateReservationCreator(with: userId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.top = self.lineView.bottom + 20
    }

    func updateReservationCreator(with userId: String) {
        User.localThenNetworkQuery(for: userId)
            .observeValue { (user) in
                runMain {
                    self.reservationUser = user
                    self.avatarView.set(avatar: user)
                    self.avatarView.isHidden = false
                    self.updateNavigationBar()
                    self.view.layoutNow()
                }
            }
    }

    override func getInitialContent() -> OnboardingContent {
        guard let status = User.current()?.status else { return .phone(self.phoneVC) }
        switch status {
        case .active, .waitlist:
            #if APPCLIP
            return .waitlist(self.waitlistVC)
            #else
            fatalError()
            #endif
        case .inactive:
            return .name(self.nameVC)
        case .needsVerification:
            return .phone(self.phoneVC)
        }
    }

    override func getTitle() -> Localized {
        guard let content = self.current else { return "" }
        switch content {
        case .phone(_):
            return "Welcome!"
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
        }
    }

    override func didSelectBackButton() {
        super.willUpdateContent()

        guard let content = self.current else { return }

        switch content {
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
                vc.editingDidEnd()
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
            if let _ = User.current()?.smallImage {
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
