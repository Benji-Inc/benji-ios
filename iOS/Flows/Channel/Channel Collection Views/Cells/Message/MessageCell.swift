//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class MessageCell: BaseMessageCell {

    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.bubbleView.onTap { [unowned self] tap in
            
            guard let current = User.current(), let message = self.currentMessage, !message.isFromCurrentUser, message.canBeConsumed, !message.hasBeenConsumedBy.contains(current.objectId!) else {
                self.didTapMessage()
                return
            }

            let location = tap.location(in: self.bubbleView)
            self.bubbleView.startFillAnimation(at: location, for: message) { [unowned self] msg in
                self.didTapMessage()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.bubbleView.layer.borderColor = nil
        self.bubbleView.layer.borderWidth = 0
        self.textView.text = nil
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        if case MessageKind.text(let text) = message.kind {
            self.textView.set(text: text, messageContext: message.context)
            self.detectDataTypes(from: text)
        }
    }

    override func handleIsConsumed(for message: Messageable) {
        self.bubbleView.set(backgroundColor: message.color)

        if !message.isFromCurrentUser, !message.isConsumed, message.context != .status {

            if !message.isFromCurrentUser, message.context == .casual {
                self.bubbleView.layer.borderColor = Color.purple.color.cgColor
            } else {
                self.bubbleView.layer.borderColor = message.context.color.color.cgColor
            }

            self.bubbleView.layer.borderWidth = 2
        }
    }

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)
        
        self.textView.frame = attributes.attributes.textViewFrame
        self.bubbleView.frame = attributes.attributes.bubbleViewFrame
        self.bubbleView.layer.maskedCorners = attributes.attributes.maskedCorners
        self.bubbleView.roundCorners()
        self.bubbleView.indexPath = attributes.indexPath
    }

    private func detectDataTypes(from string: String) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingAllTypes) else { return }

        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        detector.enumerateMatches(in: string,
                                  options: [],
                                  range: range) { (match, flags, _) in
            guard let match = match else {
                return
            }

            switch match.resultType {
            case .date:
                let date = match.date
                let timeZone = match.timeZone
                let duration = match.duration
                print(date, timeZone, duration)
            case .address:
                if let components = match.components {
                    let name = components[.name]
                    let jobTitle = components[.jobTitle]
                    let organization = components[.organization]
                    let street = components[.street]
                    let locality = components[.city]
                    let region = components[.state]
                    let postalCode = components[.zip]
                    let country = components[.country]
                    let phoneNumber = components[.phone]
                    print(name, jobTitle, organization, street, locality, region, postalCode, country, phoneNumber)
                }
            case .link:
                let url = match.url
                print(url)
            case .phoneNumber:
                let phoneNumber = match.phoneNumber
                print(phoneNumber)
            case .transitInformation:
                if let components = match.components {
                    let airline = components[.airline]
                    let flight = components[.flight]
                    print(airline, flight)
                }
            default:
                return
            }
        }
    }
}
