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
}

class InputTextView: ExpandingTextView {

    lazy var countView = CharacterCountView()
    lazy var confirmationView = AlertConfirmationView()

    private(set) var currentInputView: InputViewType?
    @Published var inputText: String = ""

    weak var attachmentDelegate: AttachmentViewControllerDelegate?

    init() {
        super.init(frame: .zero, textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
            break
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

        self.inputText = self.text
        self.countView.update(with: self.text.count, max: self.maxLength)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }
}
