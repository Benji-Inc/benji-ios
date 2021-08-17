//
//  LoginNameViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/12/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization

class NameViewController: TextInputViewController<Void> {

    init() {
        super.init(textField: TextField(),
                   title: LocalizedString(id: "", default: "FULL NAME"),
                   placeholder: LocalizedString(id: "", default: "First Last"))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.textField.autocorrectionType = .yes
        self.textField.textContentType = .name
        self.textField.keyboardType = .namePhonePad
    }

    override func textFieldDidChange() {
        super.textFieldDidChange()

        if let text = self.textField.text {
            self.textEntry.button.isEnabled = text.isValidPersonName
        } else {
            self.textEntry.button.isEnabled = false 
        }
    }

    override func didTapButton() {
        self.updateUserName()
    }

    private func updateUserName() {
        guard let text = self.textField.text, !text.isEmpty else { return }

        guard text.isValidPersonName else { return }

        self.textEntry.button.handleEvent(status: .loading)
        Task {
            do {
                User.current()?.formatName(from: text)

                try await User.current()?.saveLocalThenServer()
                self.textEntry.button.handleEvent(status: .complete)
                self.complete(with: .success(()))
            } catch {
                self.textEntry.button.handleEvent(status: .error("Failed to update user name."))
                self.complete(with: .failure(error))
            }
        }
    }
}
