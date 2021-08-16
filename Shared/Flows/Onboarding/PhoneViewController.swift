//
//  LoginPhoneViewController.swift
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

class PhoneViewController: TextInputViewController<PhoneNumber> {
    
    private(set) var isSendingCode: Bool = false

    var phoneTextField: PhoneTextField {
        return self.textField as! PhoneTextField
    }

    init() {
        let phoneField = PhoneTextField(frame: .zero)
        phoneField.withFlag = true
        phoneField.withDefaultPickerUI = true
        phoneField.withExamplePlaceholder = true

        super.init(textField: phoneField,
                   title: LocalizedString(id: "", default: "MOBILE NUMBER"),
                   placeholder: phoneField.placeholder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldBecomeFirstResponder() -> Bool {
        return !self.isPhoneNumberValid()
    }

    override func textFieldDidChange() {
        if self.isPhoneNumberValid() {
            // End editing because we have a valid phone number and we're ready to request a code with it
            self.textEntry.button.isEnabled = true
        } else if let text = self.textField.text, text.isEmpty {
            self.isSendingCode = false
            self.textEntry.button.isEnabled = false
        }
    }

    override func didTapButton() {
        guard !self.isSendingCode,
              self.isPhoneNumberValid(),
              let phone = self.phoneTextField.text?.parsePhoneNumber(for: self.phoneTextField.currentRegion) else {
                  return
              }

        Task {
            await self.sendCode(to: phone, region: self.phoneTextField.currentRegion)
        }
    }

    private func isPhoneNumberValid() -> Bool {
        if let phoneString = self.textField.text, phoneString.isValidPhoneNumber(for: self.phoneTextField.currentRegion) {
            return true
        }
        return false
    }

    private func sendCode(to phone: PhoneNumber, region: String) async {
        self.textEntry.button.handleEvent(status: .loading)
        self.isSendingCode = true

        do {
            let installation = try await PFInstallation.getCurrent()

            let _ = try await SendCode(phoneNumber: phone,
                                       region: region,
                                       installationId: installation.installationId)
                .makeAsyncRequest()
            self.textEntry.button.handleEvent(status: .complete)
            self.complete(with: .success(phone))
        } catch {
            self.textEntry.button.handleEvent(status: .error(""))
            self.complete(with: .failure(error))
        }
    }
}
