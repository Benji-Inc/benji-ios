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

        Task { await self.verify(code: code) }
    }

    // True if we're in the process of verifying the code
    private var verifying: Bool = false
    private func verify(code: String) async {
        guard !self.verifying, let phoneNumber = self.phoneNumber else { return }
        
        self.verifying = true
        self.textEntry.button.handleEvent(status: .loading)

        do {
            let installation = try await PFInstallation.getCurrent()
            let token = try await VerifyCode(code: code,
                                             phoneNumber: phoneNumber,
                                             installationId: installation.installationId,
                                             reservationId: String(optional: self.reservationId))
                .makeRequest()

            self.textField.resignFirstResponder()
            try await User.become(withSessionToken: token)
            self.textEntry.button.handleEvent(status: .complete)
            self.complete(with: .success(()))
        } catch {
            self.textEntry.button.handleEvent(status: .error(error.localizedDescription))
            self.complete(with: .failure(ClientError.message(detail: "Verification failed.")))
        }

        self.verifying = false
    }
}
