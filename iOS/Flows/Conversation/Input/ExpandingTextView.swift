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

        self.translatesAutoresizingMaskIntoConstraints = false
        self.textContainer.heightTracksTextView = true
        self.isScrollEnabled = false
        self.keyboardType = .twitter
        self.tintColor = Color.darkGray.color
        self.textColor = Color.darkGray.color

        self.textContainerInset.left = Theme.contentOffset
        self.textContainerInset.right = Theme.contentOffset
        self.textContainerInset.top = 14
        self.textContainerInset.bottom = 12
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
}
