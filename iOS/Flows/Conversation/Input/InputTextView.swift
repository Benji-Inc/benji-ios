//
//  InputTextView.swift
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
    case demo
}

class InputTextView: ExpandingTextView {

    lazy var countView = CharacterCountView()
    lazy var attachmentInputVC = AttachmentViewController(with: self.attachmentDelegate)
    lazy var demoVC = KeyboardDemoViewController()
    lazy var confirmationView = AlertConfirmationView()

    private(set) var currentInputView: InputViewType?
    @Published var inputText: String = ""

    unowned let attachmentDelegate: AttachmentViewControllerDelegate

    init(with delegate: AttachmentViewControllerDelegate) {
        self.attachmentDelegate = delegate
        super.init(frame: .zero, textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.addSubview(self.countView)
        self.countView.isHidden = true
    }

    func updateInputView(type: InputViewType, becomeFirstResponder: Bool = true) {

        defer {
            if becomeFirstResponder, !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }

        guard self.currentInputView != type else { return }

        switch type {
        case .attachments:
            self.inputView = self.attachmentInputVC.view
        case .confirmation:
            self.inputView = self.confirmationView
        case .keyboard:
            self.inputView = nil
        case .demo:
            self.inputView = self.demoVC.view
            self.demoVC.load(demos: [.send, .sendAlert, .cursor])
        }

        self.currentInputView = type
        self.reloadInputViews()
    }

    override func textDidChange() {
        super.textDidChange()

        self.inputText = self.text
        self.countView.udpate(with: self.text.count, max: self.maxLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }
}
