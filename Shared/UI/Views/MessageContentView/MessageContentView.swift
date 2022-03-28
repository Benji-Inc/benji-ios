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
    static let bubbleHeight: CGFloat = 168
    static let collapsedHeight: CGFloat = 78 - MessageContentView.bubbleTailLength
    static var collapsedBubbleHeight: CGFloat {
        return MessageContentView.collapsedHeight - MessageContentView.textViewPadding
    }
    static let authorViewHeight: CGFloat = 40

    static var standardHeight: CGFloat {
        return MessageContentView.bubbleHeight - MessageContentView.textViewPadding
    }
    static let padding = Theme.ContentOffset.long
    static var textViewPadding: CGFloat { return MessageContentView.padding.value.doubled }

    static let bubbleTailLength: CGFloat = 12

    /// A view that provides a safe area for  main message content (margins are already taken into account).
    /// Subviews includes author, attachments, text and date sent views.
    private let mainContentArea = UIView()

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    /// Date view that shows when the message was last updated.
    let dateView = ThemeLabel(font: .small, textColor: .white)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .T1)
    let imageView = DisplayableImageView()
    let linkView = LPLinkView()
    private (set) var message: Messageable?

    let authorView = PersonView()
    let emojiView = EmojiCircleView()
    
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

        self.mainContentArea.addSubview(self.linkView)

        // Make sure the author, date and emoji view are on top of the other content
        self.mainContentArea.addSubview(self.authorView)
        self.mainContentArea.addSubview(self.dateView)

        #warning("Remove testing")
        self.dateView.text = "1 Testing Ago"
        self.mainContentArea.addSubview(self.emojiView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.mainContentArea.pin(.left, offset: MessageContentView.padding)
        self.mainContentArea.pin(.top, offset: MessageContentView.padding)
        self.mainContentArea.expand(.right, to: self.bubbleView.width - MessageContentView.padding.value)
        self.mainContentArea.expand(.bottom,
                                    to: self.bubbleView.height - MessageContentView.padding.value - 25)

        self.imageView.pin(.left)
        self.imageView.pin(.top)
        self.imageView.expand(.bottom)
        if self.textView.isVisible {
            self.imageView.width = self.mainContentArea.width.half
        } else {
            self.imageView.expand(.right)
        }

        self.authorView.setSize(forHeight: MessageContentView.authorViewHeight)
        if self.imageView.isVisible {
            self.authorView.pin(.top, offset: MessageContentView.padding)
            self.authorView.pin(.left, offset: MessageContentView.padding)
        } else {
            self.authorView.pin(.top)
            self.authorView.pin(.left)
        }
        self.emojiView.center = CGPoint(x: self.authorView.width + 6,
                                        y: self.authorView.height + 6)

        self.dateView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.dateView.match(.top, to: .top, of: self.authorView)
        self.dateView.setSize(withWidth: self.mainContentArea.width - self.dateView.right)

        self.linkView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.linkView.match(.top, to: .bottom, of: self.dateView, offset: .short)
        self.linkView.width = self.mainContentArea.width.half
        self.linkView.expand(.bottom)

        if self.imageView.isVisible {
            self.textView.match(.left, to: .right, of: self.imageView, offset: MessageContentView.padding)
            self.textView.pin(.top)
            self.textView.setSize(withMaxWidth: self.mainContentArea.width - self.textView.left,
                                  maxHeight: self.mainContentArea.height)
        } else {
            self.textView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
            self.textView.match(.top, to: .bottom, of: self.dateView, offset: .short)
            self.textView.setSize(withMaxWidth: self.mainContentArea.width - self.textView.left,
                                  maxHeight: self.mainContentArea.height - self.textView.top)
        }
    }

    private var linkProvider: LPMetadataProvider?

    func configure(with message: Messageable) {
        self.message = message

        self.textView.isVisible = message.kind.hasText
        self.imageView.isVisible = message.kind.isImage
        self.linkView.isVisible = message.kind.isLink
        self.emojiView.isVisible = message.expression.exists
        
        if let expression = message.expression {
            self.emojiView.set(text: expression)
        }

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

        // NOTE: Changes to the gradient layer need to be applied immediately without animation.
        // https://stackoverflow.com/questions/5833488/how-to-disable-calayer-implicit-animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.bubbleView.lightGradientLayer.opacity = 0
        self.bubbleView.darkGradientLayer.opacity = 0.2 * Float(1 - brightness)

        CATransaction.commit()
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
}
