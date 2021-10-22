//
//  LoginTextInputViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class TextInputViewController<ResultType>: ViewController, Sizeable, Completable, UITextFieldDelegate {

    var onDidComplete: ((Result<ResultType, Error>) -> Void)?

    var textField: UITextField {
        return self.textEntry.textField
    }

    private(set) var textEntry: TextEntryField

    init(textField: UITextField,
         title: Localized,
         placeholder: Localized?) {

        self.textEntry = TextEntryField(with: textField,
                                        title: title,
                                        placeholder: placeholder)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.textEntry)

        self.textEntry.button.set(style: .normal(color: .darkGray, text: "Next"))
        self.textEntry.button.didSelect { [unowned self] in
            self.didTapButton()
        }
        self.textEntry.button.isEnabled = false

        self.textEntry.textField.addTarget(self,
                                           action: #selector(textFieldDidChange),
                                           for: UIControl.Event.editingChanged)
        self.textEntry.textField.delegate = self

        KeyboardManager.shared.addKeyboardObservers(with: nil)
        KeyboardManager.shared.$willKeyboardShow.mainSink { [unowned self] willShow in
            if willShow {
                UIView.animate(withDuration: 0.2) {
                    self.textEntry.button.alpha = 1.0
                    self.view.setNeedsLayout()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.textEntry.button.alpha = 0.0
                    self.view.setNeedsLayout()
                }
            }
        }.store(in: &self.cancellables)
    }

    func didTapButton() {}

    @objc func textFieldDidChange() {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.view.width - Theme.contentOffset.doubled
        let height = self.textEntry.getHeight(for: width)
        self.textEntry.size = CGSize(width: width, height: height)
        self.textEntry.centerOnX()

        let defaultOffset = self.view.height - KeyboardManager.shared.cachedKeyboardEndFrame.height
        self.textEntry.bottom = defaultOffset
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.shouldBecomeFirstResponder() {
            self.textEntry.textField.becomeFirstResponder()
        }
    }

    func shouldBecomeFirstResponder() -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {}
}

