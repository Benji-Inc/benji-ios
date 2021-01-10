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

    override func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateUserName()
    }

    private func updateUserName() {
        guard let text = self.textField.text, !text.isEmpty else { return }

        guard text.isValidPersonName else {
            return
        }

        let tf = self.textField as? TextField
        tf?.animationView.play()
        User.current()?.formatName(from: text)
        User.current()?.saveLocalThenServer()
            .mainSink(receiveValue: { (user) in
                tf?.animationView.stop()
                self.complete(with: .success(()))
            }).store(in: &self.cancellables)
    }
}
