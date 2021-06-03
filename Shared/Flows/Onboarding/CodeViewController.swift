//
//  LoginCodeViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhoneNumberKit
import Parse
import TMROLocalization
import Combine

class CodeViewController: TextInputViewController<Void> {

    var phoneNumber: PhoneNumber?
    var reservationId: String?
    
    init() {
        super.init(textField: TextField(),
                   title: LocalizedString(id: "", default: "CODE"),
                   placeholder: LocalizedString(id: "", default: "0000"))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textFieldDidChange() {
        if let code = self.textField.text {
            self.textEntry.button.isEnabled = code.extraWhitespaceRemoved().count == 4
        } else {
            self.textEntry.button.isEnabled = false
        }
    }

    override func didTapButton() {
        guard let code = self.textField.text, code.extraWhitespaceRemoved().count == 4 else { return }
        self.verify(code: code)
    }

    // True if we're in the process of verifying the code
    var verifying: Bool = false
    private func verify(code: String) {
        guard !self.verifying, let phoneNumber = self.phoneNumber else { return }
        
        self.verifying = true
        self.textEntry.button.handleEvent(status: .loading)

        PFInstallation.getCurrent()
            .mainSink { result in
                switch result {
                case .success(let installation):
                    VerifyCode(code: code,
                               phoneNumber: phoneNumber,
                               installationId: installation.installationId,
                               reservationId: String(optional: self.reservationId))
                        .makeRequest(andUpdate: [], viewsToIgnore: [])
                        .mainSink(receivedResult: { (result) in
                            switch result {
                            case .success(let token):
                                self.becomeUser(with: token)
                            case .error:
                                self.textEntry.button.handleEvent(status: .error(""))
                                self.complete(with: .failure(ClientError.message(detail: "Verification failed.")))
                                self.verifying = false
                            }

                            self.textField.resignFirstResponder()
                        }).store(in: &self.cancellables)
                case .error(let error):
                    self.complete(with: .failure(error))
                }
            }.store(in: &self.cancellables)
    }

    private func becomeUser(with token: String) {
        User.become(inBackground: token) { (user, error) in
            if let _ = user?.objectId {
                self.textEntry.button.handleEvent(status: .complete)
                #if !NOTIFICATION
                UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
                #endif
                self.complete(with: .success(()))
            } else if let error = error {
                self.textEntry.button.handleEvent(status: .error(error.localizedDescription))
                self.complete(with: .failure(error))
            } else {
                self.textEntry.button.handleEvent(status: .error(""))
                self.complete(with: .failure(ClientError.message(detail: "Verification failed.")))
            }

            self.verifying = false
        }
    }
}
