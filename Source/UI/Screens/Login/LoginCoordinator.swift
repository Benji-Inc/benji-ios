//
//  LoginCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit
import Parse

class LoginCoordinator: PresentableCoordinator<Void> {

    lazy var loginPhoneVC = LoginPhoneViewController(with: self)

    override func toPresentable() -> DismissableVC {
        return self.loginPhoneVC
    }

    private func fetchAllData() {
        UserNotificationManager.shared.requestAuthorization()

        PFAnonymousUtils.logIn { (user, error) in
            if error != nil || user == nil {
                print("Anonymous login failed.")
            } else {
                self.runHomeFlow()
            }
        }
    }

    private func runHomeFlow() {
        let coordinator = HomeCoordinator(router: self.router, deepLink: self.deepLink)
        self.router.setRootModule(coordinator, animated: true)
        self.addChildAndStart(coordinator, finishedHandler: { _ in
            // If the home coordinator ever finishes, put handling logic here.
        })
    }
}

extension LoginCoordinator: LoginFlowViewControllerDelegate {
    func loginFlowViewController(_ controller: LoginFlowViewController, finishedWith result: LoginFlowResult) {
        switch result {
        case .loggedIn:
            break 
            //self.loginFlowController.dismiss(animated: true, completion: nil)
        case .cancelled:
            break 
        }
    }
}

extension LoginCoordinator: LoginPhoneViewControllerDelegate {
    func loginPhoneView(_ controller: LoginPhoneViewController, didCompleteWith phone: PhoneNumber) {
        let controller = LoginCodeViewController(with: self, phoneNumber: phone)
        self.router.push(controller)
    }
}

extension LoginCoordinator: LoginCodeViewControllerDelegate {
    func loginCodeView(_ controller: LoginCodeViewController, didVerify user: PFUser) {
        let controller = LoginNameViewController(with: self)
        self.router.push(controller)
    }
}

extension LoginCoordinator: LoginNameViewControllerDelegate {
    func loginNameViewControllerDidComplete(_ controller: LoginNameViewController) {
        let controller = LoginProfilePhotoViewController(with: self)
        self.router.push(controller)
    }
}

extension LoginCoordinator: LoginProfilePhotoViewControllerDelegate {
    func loginProfilePhotoViewControllerDidUpdatePhoto(_ controller: LoginProfilePhotoViewController) {
        self.runHomeFlow()
    }
}
