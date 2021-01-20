//
//  MessageInputTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum InputViewType {
    case attachments
    case confirmation
    case keyboard
}

class MessageInputTextView: InputTextView {

    lazy var countView = CharacterCountView()
    lazy var attachmentInputVC = AttachmentViewController()
    lazy var confirmationView = AlertConfirmationView()

    private(set) var currentInputView: InputViewType = .keyboard
    var textDidChange: ((String) -> Void)?

    override var canResignFirstResponder: Bool {
        return false 
    }

    override func initialize() {
        super.initialize()

        self.addSubview(self.countView)
        self.countView.isHidden = true
    }

    func updateInputView(type: InputViewType) {
        defer {
            if !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }

        switch type {
        case .attachments:
            self.inputView = self.attachmentInputVC.view
        case .confirmation:
            self.inputView = self.confirmationView
        case .keyboard:
            self.inputView = nil
        }

        self.currentInputView = type

        UIView.animate(withDuration: 0.2) {
            self.reloadInputViews()
        } completion: { (completed) in }
    }

    override func textDidChange(notification: Notification) {
        super.textDidChange(notification: notification)
        self.countView.udpate(with: self.text.count, max: self.maxLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }
}
