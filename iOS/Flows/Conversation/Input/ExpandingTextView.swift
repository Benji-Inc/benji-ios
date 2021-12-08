//
//  InputTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpandingTextView: TextView {

    private var initialPlaceholder: String?

    init() {
        super.init(frame: .zero,
                   font: .regular,
                   textColor: .textColor,
                   textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.font = FontType.regular.font
        self.textColor = Color.textColor.color
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.translatesAutoresizingMaskIntoConstraints = false
        self.textContainer.heightTracksTextView = true
        self.isScrollEnabled = false
        self.keyboardType = .twitter
        self.tintColor = Color.textColor.color
        self.textColor = Color.textColor.color

        self.textContainerInset.left = Theme.ContentOffset.long.value
        self.textContainerInset.right = Theme.ContentOffset.long.value
        self.textContainerInset.top = Theme.ContentOffset.long.value
        self.textContainerInset.bottom = Theme.ContentOffset.long.value
    }

    func setPlaceholder(for avatars: [Avatar], isReply: Bool) {
        var placeholderText = isReply ? "Reply to" : "Message "

        if avatars.isEmpty {
            placeholderText = isReply ? "Reply" : "Message"
        }

        for (index, avatar) in avatars.enumerated() {
            if index < avatars.count - 1 {
                placeholderText.append(String("\(avatar.givenName), "))
            } else if index == avatars.count - 1 && avatars.count > 1 {
                placeholderText.append(String("and \(avatar.givenName)"))
            } else {
                placeholderText.append(avatar.givenName)
            }
        }

        self.initialPlaceholder = placeholderText
        self.set(placeholder: placeholderText, color: .lightGray)
    }

    func setPlaceholder(for kind: MessageKind) {
        switch kind {
        case .text(_):
            if let placeholder = self.initialPlaceholder {
                self.set(placeholder: placeholder, color: .darkGray)
            }
        case .photo(_, _), .video(_, _):
            self.set(placeholder: "Add comment", color: .darkGray)
        default:
            break
        }
    }

    override func textViewDidBeginEditing() {
        super.textViewDidBeginEditing()
        self.set(placeholder: "", color: .lightGray)
        self.setNeedsDisplay()
    }

    override func textDidEndEditing() {
        super.textDidEndEditing()
        self.set(placeholder: self.initialPlaceholder ?? "", color: .lightGray)
        self.setNeedsDisplay()
    }
}
