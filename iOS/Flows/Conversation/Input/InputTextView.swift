//
//  InputTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTextView: ExpandingTextView {

    lazy var countView = CharacterCountView()
    lazy var confirmationView = AlertConfirmationView()
    lazy var placeholderView = InputPlaceholderView()

    private(set) var currentInputType: InputType?
    @Published var inputText: String = ""

    weak var attachmentDelegate: AttachmentViewControllerDelegate?

    init() {
        super.init(frame: .zero,
                   font: .regularBold,
                   textColor: .textColor,
                   textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.font = FontType.regularBold.font
        self.textColor = Color.textColor.color
    }

    override func initializeViews() {
        super.initializeViews()

        self.addSubview(self.countView)
        self.countView.isHidden = true
    }

    func updateInputView(type: InputType, becomeFirstResponder: Bool = true) {
        defer {
            if becomeFirstResponder, !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }

        guard self.currentInputType != type else { return }

        switch type {
        case .confirmation:
            self.inputView = self.confirmationView
        case .keyboard:
            self.inputView = nil
        case .photo, .video, .calendar, .jibs:
            self.placeholderView.configure(with: type)
            self.inputView = self.placeholderView
        }

        self.currentInputType = type
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
