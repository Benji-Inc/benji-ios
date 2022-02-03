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
                   textColor: .T1,
                   textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.font = FontType.regular.font
        self.setTextColor(.T1)
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.maxLength = 140

        self.translatesAutoresizingMaskIntoConstraints = false
        self.textContainer.heightTracksTextView = true
        self.isScrollEnabled = false
        self.keyboardType = .twitter
        self.tintColor = ThemeColor.T1.color.resolvedColor(with: self.traitCollection)

        self.textContainerInset.left = Theme.ContentOffset.long.value
        self.textContainerInset.right = Theme.ContentOffset.long.value
        self.textContainerInset.top = Theme.ContentOffset.long.value + 1
        self.textContainerInset.bottom = Theme.ContentOffset.long.value
    }

    func setPlaceholder(for avatars: [Avatar], isReply: Bool) {
        var placeholderText = isReply ? "Reply to " : "Message "

        if avatars.isEmpty {
            placeholderText = isReply ? "Add Reply" : "Message Someone"
        }
        
        switch avatars.count {
        case 1:
            if let avatar = avatars[safe: 0] {
                placeholderText.append(avatar.givenName)
            }
        case 2:
            if let avatar1 = avatars[safe: 0], let avatar2 = avatars[safe: 1] {
                placeholderText.append("\(avatar1.givenName) and \(avatar2.givenName)")
            }
        case 3:
            if let avatar1 = avatars[safe: 0],
               let avatar2 = avatars[safe: 1],
               let avatar3 = avatars[safe: 2] {
                placeholderText.append("\(avatar1.givenName), \(avatar2.givenName), and \(avatar3.givenName)")
            }
        default:
            if !avatars.isEmpty {
                placeholderText.append("\(avatars.count) people")
            }
        }

        self.initialPlaceholder = placeholderText
        self.set(placeholder: placeholderText)
    }

    func setPlaceholder(for kind: MessageKind) {
        switch kind {
        case .text(_):
            if let placeholder = self.initialPlaceholder {
                self.set(placeholder: placeholder)
            }
        case .photo(_, _), .video(_, _):
            self.set(placeholder: "Add comment")
        default:
            break
        }
    }

    override func textViewDidBeginEditing() {
        super.textViewDidBeginEditing()

        self.set(placeholder: "")
        self.setNeedsDisplay()
    }

    override func textViewDidEndEditing() {
        super.textViewDidEndEditing()

        self.set(placeholder: self.initialPlaceholder ?? "")
        self.setNeedsDisplay()
    }
}
