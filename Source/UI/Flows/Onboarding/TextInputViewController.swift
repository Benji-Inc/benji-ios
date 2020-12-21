//
//  LoginTextInputViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class TextInputViewController<ResultType>: ViewController, Sizeable, Completable, UITextFieldDelegate, KeyboardObservable {

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

        self.textEntry.textField.addTarget(self,
                                           action: #selector(textFieldDidChange),
                                           for: UIControl.Event.editingChanged)
        self.textEntry.textField.delegate = self
        self.registerKeyboardEvents()
    }

    @objc func textFieldDidChange() {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.view.width - (Theme.contentOffset * 2)
        let height = self.textEntry.getHeight(for: width)
        self.textEntry.size = CGSize(width: width, height: height)
        self.textEntry.centerOnX()

        let defaultOffset = self.view.height - 340
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

    func handleKeyboard(frame: CGRect,
                        with animationDuration: TimeInterval,
                        timingCurve: UIView.AnimationCurve) {
        self.view.layoutNow()
    }
}

