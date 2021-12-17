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
        phoneField.textColor = ThemeColor.darkGray.color

        super.init(textField: phoneField, placeholder: phoneField.placeholder)

        phoneField.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldBecomeFirstResponder() -> Bool {
        return !self.isPhoneNumberValid()
    }

    override func textFieldDidChange() {
        super.textFieldDidChange()

         if let text = self.textField.text, text.isEmpty {
            self.isSendingCode = false
        }
    }

    override func validate(text: String) -> Bool {
        return self.isPhoneNumberValid()
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
        await self.button.handleEvent(status: .loading)
        self.isSendingCode = true

        do {
            let installation = try await PFInstallation.getCurrent()

            let _ = try await SendCode(phoneNumber: phone,
                                       region: region,
                                       installationId: installation.installationId)
                .makeRequest()
            await self.button.handleEvent(status: .complete)
            self.complete(with: .success(phone))
        } catch {
            await self.button.handleEvent(status: .error(""))
            self.complete(with: .failure(error))
        }
    }
}
