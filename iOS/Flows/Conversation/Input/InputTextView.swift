//
//  InputTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum InputType {

    case photo
    case video
    case keyboard
    case calendar
    case jibs
    case confirmation

    var image: UIImage? {
        switch self {
        case .photo:
            return UIImage(systemName: "photo")
        case .video:
            return UIImage(systemName: "video")
        case .keyboard:
            return UIImage(systemName: "abc")
        case .calendar:
            return UIImage(systemName: "calendar")
        case .jibs:
            return UIImage(systemName: "bitcoinsign.circle")
        case .confirmation:
            return nil
        }
    }
}

class InputTextView: ExpandingTextView {

    lazy var countView = CharacterCountView()
    lazy var confirmationView = AlertConfirmationView()

    private(set) var currentInputType: InputType?
    @Published var inputText: String = ""

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
            self.inputView = nil
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
