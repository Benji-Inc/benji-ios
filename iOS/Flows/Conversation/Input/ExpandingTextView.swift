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
                   textColor: .white,
                   textContainer: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.font = FontType.regular.font
        self.setTextColor(.white)
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.translatesAutoresizingMaskIntoConstraints = false
        self.textContainer.heightTracksTextView = true
        self.isScrollEnabled = false
        self.keyboardType = .twitter
        self.tintColor = ThemeColor.white.color.resolvedColor(with: self.traitCollection)

        self.textContainerInset.left = Theme.ContentOffset.standard.value
        self.textContainerInset.right = Theme.ContentOffset.standard.value
        self.textContainerInset.top = Theme.ContentOffset.long.value + 1
        self.textContainerInset.bottom = Theme.ContentOffset.long.value
    }
    
    func setPlaceholderForComments() {
        self.initialPlaceholder = "Add Comment"
        self.set(placeholder: "Add Comment", alignment: .left)
    }
    

    func setPlaceholder(for people: [PersonType], isReply: Bool) {
        var placeholderText = isReply ? "Reply to " : "Message "

        if people.isEmpty {
            placeholderText = isReply ? "Add Reply" : "Message Someone"
        }
        
        switch people.count {
        case 1:
            if let person = people[safe: 0] {
                placeholderText.append(person.givenName)
            }
        case 2:
            if let person1 = people[safe: 0], let person2 = people[safe: 1] {
                placeholderText.append("\(person1.givenName) and \(person2.givenName)")
            }
        case 3:
            if let person1 = people[safe: 0],
               let person2 = people[safe: 1],
               let person3 = people[safe: 2] {
                placeholderText.append("\(person1.givenName), \(person2.givenName), and \(person3.givenName)")
            }
        default:
            if !people.isEmpty {
                placeholderText.append("\(people.count) people")
            }
        }

        self.initialPlaceholder = placeholderText
        self.set(placeholder: placeholderText, alignment: .left)
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

    // MARK: - TextView Event Handlers

    override func textViewDidBeginEditing() {
        super.textViewDidBeginEditing()

        // Hide the placeholder when the user wants to start typing a message.
        self.set(placeholder: "")
        self.setNeedsDisplay()
    }

    override func textViewDidEndEditing() {
        super.textViewDidEndEditing()

        self.set(placeholder: self.initialPlaceholder ?? "")
        self.setNeedsDisplay()
    }
}
