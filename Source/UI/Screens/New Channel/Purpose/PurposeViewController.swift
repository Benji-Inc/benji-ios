//
//  PurposeViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class PurposeViewController: ViewController {

    let offset: CGFloat = 20

    let textFieldTitleLabel = RegularBoldLabel()
    let textField = PurposeTitleTextField()

    let textViewTitleLabel = RegularBoldLabel()
    let textView = PurposeDescriptionTextView()

    let purposeAccessoryView = PurposeInputAccessoryView()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.textFieldTitleLabel)
        self.textFieldTitleLabel.set(text: "Name", stringCasing: .unchanged)
        self.view.addSubview(self.textField)
        self.textField.set(backgroundColor: .background3)
        self.textField.roundCorners()

        self.view.addSubview(self.textViewTitleLabel)
        self.textViewTitleLabel.set(text: "Description", stringCasing: .unchanged)
        self.view.addSubview(self.textView)
        self.textView.set(backgroundColor: .background3)
        self.textView.roundCorners()
        self.textView.delegate = self

        self.textField.onTextChanged = { [unowned self] in
            self.handleTextChange()
        }

        self.textField.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.view.width - (self.offset * 2)

        self.textFieldTitleLabel.setSize(withWidth: width)
        self.textFieldTitleLabel.top = 20
        self.textFieldTitleLabel.left = self.offset

        self.textField.size = CGSize(width: width, height: 40)
        self.textField.left = self.offset
        self.textField.top = self.textFieldTitleLabel.bottom + 10

        self.textViewTitleLabel.setSize(withWidth: width)
        self.textViewTitleLabel.top = self.textField.bottom + 30
        self.textViewTitleLabel.left = self.offset

        self.textView.size = CGSize(width: width, height: 120)
        self.textView.top = self.textViewTitleLabel.bottom + 10
        self.textView.left = self.offset
    }

    private func handleTextChange() {
        guard let text = self.textField.text else { return }
        self.textField.text = text.lowercased()
        self.updateCreateButton()
    }

    private func updateCreateButton() {
        guard let text = self.textField.text else {
            //self.createButton.isEnabled = false
            return
        }


        // self.createButton.isEnabled = !text.isEmpty
    }

    private func createTapped() {
        guard let title = self.textField.text,
            let description = self.textView.text else { return }

        //  self.createChannel(with: user.objectId!, title: title, description: description)
    }

    private func showAccessoryForName() {
        self.purposeAccessoryView.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.width,
                                                 height: 60)
        self.purposeAccessoryView.keyboardAppearance = self.textField.keyboardAppearance
        self.purposeAccessoryView.text = LocalizedString(id: "", arguments: [], default: "Names must be lowercase, without spaces or periods, and can't be longer than 80 characters.")
        self.textField.inputAccessoryView = self.purposeAccessoryView
        self.textField.reloadInputViews()
    }

    private func showAccessoryForDescription() {
        self.purposeAccessoryView.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.width,
                                                 height: 60)
        self.purposeAccessoryView.keyboardAppearance = self.textView.keyboardAppearance
        self.purposeAccessoryView.text = LocalizedString(id: "",arguments: [], default: "Briefly describe the purpose of this conversation.")
        self.textView.inputAccessoryView = self.purposeAccessoryView
        self.textView.reloadInputViews()
    }
}

extension PurposeViewController: UITextViewDelegate {

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {

        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.showAccessoryForDescription()
    }
}

extension PurposeViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.showAccessoryForName()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if string == " " || string == "." {
            return false
        }

        if string.count > 80 {
            return false
        }

        return true
    }
}
