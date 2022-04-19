//
//  LoginTextInputViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization
import UIKit
 
class TextFieldToolBar: UIToolbar {

    init(button: UIBarButtonItem) {
        super.init(frame: .init(origin: .zero,
                                size: CGSize(width: UIScreen.main.bounds.width,
                                             height: Theme.buttonHeight + Theme.ContentOffset.standard.value.doubled)))
        self.setItems([button], animated: false)
        self.isTranslucent = true
        self.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.set(backgroundColor: .clear)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TextInputViewController<ResultType>: ViewController, Sizeable, Completable, UITextFieldDelegate {

    var onDidComplete: ((Result<ResultType, Error>) -> Void)?

    var textField: UITextField {
        return self.textEntry.textField
    }

    private(set) var textEntry: TextEntryField

    lazy var button: ThemeButton = {
        let button = ThemeButton()
        button.set(style: .custom(color: .B5, textColor: .B0, text: "Next"))
        button.height = Theme.buttonHeight
        button.didSelect { [unowned self] in
            self.didTapButton()
        }
        return button
    }()

    lazy var barButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem.init(customView: self.button)
        return barButton
    }()

    lazy var toolbar = TextFieldToolBar(button: self.barButton)

    init(textField: UITextField, placeholder: Localized?) {

        self.textEntry = TextEntryField(with: textField, placeholder: placeholder)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.textEntry)

        self.textEntry.textField.addTarget(self,
                                           action: #selector(textFieldDidChange),
                                           for: UIControl.Event.editingChanged)
        self.textEntry.textField.delegate = self

        KeyboardManager.shared.$cachedKeyboardEndFrame.mainSink { [weak self] _ in
            guard let `self` = self else { return }
            UIView.animate(withDuration: 0.01) {
                self.view.setNeedsLayout()
            }
        }.store(in: &self.cancellables)
    }

    func didTapButton() {}

    @objc func textFieldDidChange() {
        guard let text = self.textField.text else {
            self.textField.inputAccessoryView = nil
            self.textField.autocorrectionType = .default
            self.textField.reloadInputViews()
            return
        }

        let isValid = self.validate(text: text)

        self.textField.inputAccessoryView = isValid ? self.toolbar : nil
        self.textField.autocorrectionType = isValid ? .no : .default
        self.textField.reloadInputViews()
    }

    func validate(text: String) -> Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.view.width - Theme.contentOffset.doubled
        let height = self.textEntry.getHeight(for: width)
        self.textEntry.size = CGSize(width: width, height: height)
        self.textEntry.centerOnX()

        let defaultOffset = self.view.height - KeyboardManager.shared.cachedKeyboardEndFrame.height - Theme.contentOffset.half
        self.textEntry.bottom = defaultOffset
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.becomeFirstResponder()

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

