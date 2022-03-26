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
    static var textViewPadding: CGFloat { return MessageContentView.padding.value * 2 }

    static let bubbleTailLength: CGFloat = 12

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .T1)
    let displayableView = DisplayableImageView()
    let linkView = LPLinkView()
    private (set) var message: Messageable?

    let authorView = PersonView()
    let emojiView = EmojiCircleView()
    
    var layoutState: Layout = .expanded

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.bubbleView)
        self.bubbleView.roundCorners()

        self.bubbleView.addSubview(self.displayableView)
        self.displayableView.imageView.contentMode = .scaleAspectFill
        self.displayableView.roundCorners()

        self.bubbleView.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.textView.textAlignment = .left

        self.bubbleView.addSubview(self.linkView)

        self.bubbleView.addSubview(self.authorView)
        self.bubbleView.addSubview(self.emojiView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.authorView.setSize(forHeight: MessageContentView.authorViewHeight)
        self.authorView.pin(.top, offset: MessageContentView.padding)
        self.authorView.pin(.left, offset: MessageContentView.padding)
        
        self.emojiView.center = CGPoint(x: self.authorView.width + 6,
                                        y: self.authorView.height + 6)

        self.textView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.textView.pin(.top, offset: MessageContentView.padding)
        if self.displayableView.displayable.exists {
            // If there's also an image to display, then limit the text view height.
            let maxHeight = MessageContentView.authorViewHeight
            self.textView.setSize(withMaxWidth: self.width - self.textView.left - MessageContentView.padding.value,
                                  maxHeight: maxHeight)
        } else {
            // If there's no image to display, the text view can take up all the available vertical space.
            self.textView.setSize(withMaxWidth: self.width - self.textView.left - MessageContentView.padding.value,
                                  maxHeight: self.height - self.textView.top - MessageContentView.padding.value - 25)
        }

        self.displayableView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        if self.textView.text.isEmpty {
            // If there's no text, then the image will take up all available vertical space.
            self.displayableView.match(.top, to: .top, of: self.authorView)
        } else {
            // If there is text, then fit the image in the remaining vertical space under the image.
            self.displayableView.match(.top, to: .bottom, of: self.textView, offset: MessageContentView.padding)
        }

        self.linkView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.linkView.pin(.top, offset: MessageContentView.padding)
        self.linkView.expand(.right, to: self.width - MessageContentView.padding.value)
        self.linkView.expand(.bottom, to: self.height - MessageContentView.padding.value - 25)

        // Expand the image to fill in the remaining height.
        self.displayableView.expand(.bottom, to: self.height - MessageContentView.padding.value - 25)
        self.displayableView.width = self.displayableView.height
    }

    private var linkProvider: LPMetadataProvider?

    func configure(with message: Messageable) {
        self.message = message

        self.textView.isVisible = message.kind.hasText
        self.displayableView.isVisible = message.kind.isImage
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
                self.displayableView.displayable = previewUrl
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
                    }
                }
            case .text, .attributedText, .video, .location, .emoji, .audio, .contact:
                self.displayableView.isVisible = false
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
