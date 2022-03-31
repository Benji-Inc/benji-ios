//
//  MessageContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import LinkPresentation

class MessageContentView: BaseView {
    
    enum Layout {
        case collapsed
        case expanded
    }

    // Sizing
    static let bubbleHeight: CGFloat = 188
    static let collapsedHeight: CGFloat = 78 - MessageContentView.bubbleTailLength
    static var collapsedBubbleHeight: CGFloat {
        return MessageContentView.collapsedHeight - MessageContentView.textViewPadding
    }
    static let authorViewHeight: CGFloat = 38

    static var standardHeight: CGFloat {
        return MessageContentView.bubbleHeight - MessageContentView.textViewPadding
    }
    static let padding = Theme.ContentOffset.long
    static var textViewPadding: CGFloat { return MessageContentView.padding.value.doubled }

    static let bubbleTailLength: CGFloat = 12

    private (set) var message: Messageable?

    /// A view that provides a safe area for  main message content (margins are already taken into account).
    /// Subviews includes author, attachments, text and date sent views.
    private let mainContentArea = UIView()

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    let authorView = PersonView()
    let emojiView = EmojiCircleView()
    /// Date view that shows when the message was last updated.
    let dateView = ThemeLabel(font: .small, textColor: .white)
    /// Delivery view that shows how the message was sent
    let deliveryView = UIImageView()
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .T1)
    let imageView = DisplayableImageView()
    let linkView = LPLinkView()

    var layoutState: Layout = .expanded

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.bubbleView)
        self.bubbleView.roundCorners()

        self.bubbleView.addSubview(self.mainContentArea)

        self.mainContentArea.addSubview(self.imageView)
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.roundCorners()

        self.mainContentArea.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.textView.textAlignment = .left
        self.textView.isVisible = false
        self.mainContentArea.addSubview(self.linkView)

        // Make sure the author, date and emoji view are on top of the other content
        self.mainContentArea.addSubview(self.authorView)
        self.mainContentArea.addSubview(self.deliveryView)
        self.deliveryView.contentMode = .scaleAspectFit
        self.deliveryView.alpha = 0.6
        self.deliveryView.tintColor = ThemeColor.white.color
        
        self.mainContentArea.addSubview(self.dateView)
        self.dateView.alpha = 0.6
        self.mainContentArea.addSubview(self.emojiView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.mainContentArea.pin(.left, offset: MessageContentView.padding)
        self.mainContentArea.pin(.top, offset: MessageContentView.padding)
        self.mainContentArea.expand(.right, padding: MessageContentView.padding.value)
        self.mainContentArea.expand(.bottom, padding: MessageContentView.padding.value)

        // Author and Emoji
        self.authorView.setSize(forHeight: MessageContentView.authorViewHeight)
        self.authorView.pin(.top)
        self.authorView.pin(.left)

        self.emojiView.center = CGPoint(x: self.authorView.width - Theme.ContentOffset.short.value,
                                        y: self.authorView.height)
        
        // Delivery View
        self.deliveryView.squaredSize = 11
        self.deliveryView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)

        // Date view
        self.dateView.match(.left, to: .right, of: self.deliveryView, offset: .short)
        self.dateView.match(.top, to: .top, of: self.authorView)
        self.dateView.setSize(withWidth: self.mainContentArea.width - self.dateView.left)
        
        self.deliveryView.centerY = self.dateView.centerY

        // Link view
        self.linkView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.linkView.match(.top, to: .bottom, of: self.dateView, offset: .short)
        self.linkView.expand(.right)
        self.linkView.expand(.bottom)

        // Text view
        self.textView.match(.top, to: .bottom, of: self.dateView, offset: .short)
        self.textView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        if self.imageView.isVisible {
            self.textView.width = (self.mainContentArea.width - self.textView.left).half
        } else {
            self.textView.expand(.right)
        }
        self.textView.expand(.bottom)
        self.textView.updateFontSize(state: self.layoutState)

        // Image view
        if self.textView.isVisible {
            self.imageView.pin(.top)
            self.imageView.match(.left, to: .right, of: self.textView, offset: .short)
        } else {
            self.imageView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
            self.imageView.match(.top, to: .bottom, of: self.dateView, offset: .short)
        }
        self.imageView.expand(.right)
        self.imageView.expand(.bottom)
    }

    private var linkProvider: LPMetadataProvider?

    func configure(with message: Messageable) {
        self.message = message

        self.textView.isVisible = message.kind.hasText && !message.kind.isLink
        self.imageView.isVisible = message.kind.isImage
        self.linkView.isVisible = message.kind.isLink
        self.emojiView.isVisible = message.expression.exists
        
        if let expression = message.expression {
            self.emojiView.set(text: expression)
        }

        self.dateView.text = message.createdAt.getTimeAgoString()
        self.deliveryView.image = message.deliveryType.image

        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)

            switch message.kind {
            case .photo(photo: let photo, _):
                guard let previewUrl = photo.previewUrl else { break }
                self.imageView.displayable = previewUrl
            case .link(url: let url, _):
                self.linkProvider?.cancel()

                let initialMetadata = LPLinkMetadata()
                initialMetadata.originalURL = url
                self.linkView.metadata = initialMetadata

                self.linkProvider = LPMetadataProvider()
                self.linkProvider?.startFetchingMetadata(for: url) { (metadata, error) in
                    Task.onMainActor {
                        guard let metadata = metadata else { return }
                        self.linkView.metadata = metadata
                        self.setNeedsLayout()
                    }
                }
            case .text, .attributedText, .video, .location, .emoji, .audio, .contact:
                self.imageView.isVisible = false
                self.linkView.isVisible = false
                break
            }
        }

        self.authorView.set(person: message.person)

        self.setNeedsLayout()
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: UIColor,
                             textColor: UIColor,
                             brightness: CGFloat,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.textView.textColor = textColor
        self.textView.linkTextAttributes = [.foregroundColor: textColor.withAlphaComponent(0.5), .underlineStyle: 0]

        self.bubbleView.setBubbleColor(color.withAlphaComponent(brightness), animated: false)
        self.bubbleView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.bubbleView.orientation = tailOrientation
    }

    func getSize(with width: CGFloat) -> CGSize {
        var size = self.textView.getSize(width: width, layout: self.layoutState)
        size.width += MessageContentView.textViewPadding
        size.height += self.bubbleView.tailLength + MessageContentView.textViewPadding
        return size
    }
}

extension MessageTextView {

    func getSize(width: CGFloat, layout: MessageContentView.Layout = .expanded) -> CGSize {
        let maxTextWidth: CGFloat
        var maxTextHeight: CGFloat = MessageContentView.standardHeight
        
        if layout == .collapsed {
            maxTextHeight = MessageContentView.collapsedBubbleHeight
        }
        
        let size = CGSize(width: MessageContentView.authorViewHeight,
                          height: MessageContentView.authorViewHeight)
        maxTextWidth = width - (size.width + (MessageContentView.textViewPadding + MessageContentView.textViewPadding.half))

        return self.getSize(withMaxWidth: maxTextWidth, maxHeight: maxTextHeight)
    }

    /// Updates the font size to be appropriate for the amount of text displayed.
    fileprivate func updateFontSize(state: MessageContentView.Layout) {
        
        if state == .collapsed {
            self.font = FontType.regular.font
            return
        }
        
        self.font = FontType.contextCues.font

        guard self.numberOfLines > 1 else { return }

        self.font = FontType.medium.font

        guard self.numberOfLines > 1 else { return }

        self.font = FontType.regular.font
    }
}
