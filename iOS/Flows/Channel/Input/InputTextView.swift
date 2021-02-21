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

class InputTextView: ExpandingTextView {

    lazy var countView = CharacterCountView()
    lazy var attachmentInputVC = AttachmentViewController(with: self.attachmentDelegate)
    lazy var confirmationView = AlertConfirmationView()

    private(set) var currentInputView: InputViewType = .keyboard
    var textDidUpdate: ((String) -> Void)?

    unowned let attachmentDelegate: AttachmentViewControllerDelegate

    init(with delegate: AttachmentViewControllerDelegate) {
        self.attachmentDelegate = delegate
        super.init(frame: .zero, textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initialize() {
        super.initialize()

        self.addSubview(self.countView)
        self.countView.isHidden = true
    }

    func updateInputView(type: InputViewType, becomeFirstResponder: Bool = true) {
        defer {
            if becomeFirstResponder, !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }

        switch type {
        case .attachments:
            self.attachmentInputVC.collectionViewManager.reset()
            self.inputView = self.attachmentInputVC.view
        case .confirmation:
            self.inputView = self.confirmationView
        case .keyboard:
            self.inputView = nil
        }

        self.currentInputView = type
        self.reloadInputViews()
    }

    override func textDidChange() {
        super.textDidChange()
        self.textDidUpdate?(self.text)
        self.countView.udpate(with: self.text.count, max: self.maxLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }
}
