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
import StreamChat

@MainActor
protocol MessageContentDelegate: AnyObject {
    func messageContent(_ content: MessageContentView, didTapViewReplies messageInfo: (ConversationId, MessageId))
    func messageContent(_ content: MessageContentView, didTapMessage messageInfo: (ConversationId, MessageId))
    func messageContent(_ content: MessageContentView, didTapEditMessage messageInfo: (ConversationId, MessageId))
    func messageContent(_ content: MessageContentView, didTapAttachmentForMessage messageInfo: (ConversationId, MessageId))
    func messageContent(_ content: MessageContentView, didTapAddExpressionForMessage messageInfo: (ConversationId, MessageId))
    func messageContent(_ content: MessageContentView,
                        didTapEmotion emotion: Emotion,
                        for expression: ExpressionInfo,
                        forMessage messageInfo: (ConversationId, MessageId))
}

extension MessageContentDelegate {
    func messageContent(_ content: MessageContentView, didTapAddExpressionForMessage messageInfo: (ConversationId, MessageId)) {}
    
    func messageContent(_ content: MessageContentView,
                        didTapEmotion emotion: Emotion,
                        for expression: ExpressionInfo,
                        forMessage messageInfo: (ConversationId, MessageId)) {}
}

class MessageContentView: BaseView {
    
    enum Layout {
        case collapsed
        case expanded
    }

    // Sizing
    static let bubbleHeight: CGFloat = UIScreen.currentSize == .phoneMedium ? 148 : 188
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
    let mainContentArea = UIView()

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    let authorView = PersonGradientView()
    /// Date view that shows when the message was last updated.
    let dateView = MessageDateLabel(font: .small)
    /// Delivery view that shows how the message was sent
    let deliveryView = UIImageView()
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .white)
    let imageView = DisplayableImageView()
    let countCircle = CircleCountView()
    let videoImageView = UIImageView(image: UIImage(systemName: "video.fill"))
    let linkView = LPLinkView()

    /// A view to blur out the emotions collection view.
    let blurView = BlurView()
    lazy var emotionCollectionView = EmotionCircleCollectionView(cellDiameter: self.cellDiameter)
    
    let emotionLabel = ThemeLabel(font: .regular)
    let addEmotionButton = ThemeButton()
    let addEmotionImageView = UIImageView(image: UIImage(systemName: "plus"))

    var areEmotionsShown: Bool {
        return self.blurView.effect == nil
    }
    
    var layoutState: Layout = .expanded
    private let cellDiameter: CGFloat
    
    /// Delegate
    weak var delegate: MessageContentDelegate?
    
    init(with cellDiameter: CGFloat = 80) {
        self.cellDiameter = cellDiameter
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cellDiameter = 80
        super.init(coder: aDecoder)
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.bubbleView)
        self.bubbleView.roundCorners()

        self.bubbleView.addSubview(self.emotionCollectionView)

        self.bubbleView.addSubview(self.blurView)
        self.bubbleView.addSubview(self.emotionLabel)
        self.emotionLabel.setText("Empty")
        self.emotionLabel.alpha = 0 
        
        self.addEmotionImageView.contentMode = .scaleAspectFit
        self.addEmotionImageView.tintColor = ThemeColor.white.color
        self.bubbleView.addSubview(self.addEmotionImageView)
        self.addEmotionImageView.alpha = 0
        self.bubbleView.addSubview(self.addEmotionButton)
        self.addEmotionButton.set(style: .normal(color: .clear, text: ""))
        self.addEmotionButton.alpha = 0

        self.bubbleView.addSubview(self.mainContentArea)

        self.mainContentArea.addSubview(self.imageView)
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.roundCorners()
        
        self.mainContentArea.addSubview(self.countCircle)
        
        self.mainContentArea.addSubview(self.videoImageView)
        self.videoImageView.tintColor = ThemeColor.white.color
        self.videoImageView.contentMode = .scaleAspectFit

        self.mainContentArea.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.textView.textAlignment = .left
        self.textView.isVisible = false
        self.mainContentArea.addSubview(self.linkView)

        // Make sure the author, date and emoji view are on top of the other content
        self.mainContentArea.addSubview(self.authorView)
        self.authorView.set(backgroundColor: .B6)
        self.authorView.layer.cornerRadius = Theme.innerCornerRadius
        
        self.mainContentArea.addSubview(self.deliveryView)
        self.deliveryView.contentMode = .scaleAspectFit
        self.deliveryView.alpha = 0.6
        self.deliveryView.tintColor = ThemeColor.white.color
        
        self.mainContentArea.addSubview(self.dateView)
        self.dateView.alpha = 0.6

        self.setupHandlers()
    }
    
    private func setupHandlers() {
        self.authorView.didSelect { [unowned self] in
            self.setEmotions(areShown: !self.areEmotionsShown, animated: true)
        }

        self.emotionCollectionView.onTappedBackground = { [unowned self] in
            self.setEmotions(areShown: false, animated: true)
        }

        self.emotionCollectionView.onTappedEmotion = { [unowned self] emotion in
            guard let message = self.message, let cid = message.streamCid,
                  let expression = self.message?.authorExpression  else { return }
            self.delegate?.messageContent(self,
                                          didTapEmotion: emotion,
                                          for: expression,
                                          forMessage: (cid, message.id))
        }
        
        self.imageView.didSelect { [unowned self] in
            guard let message = self.message, let cid = message.streamCid else { return }
            self.delegate?.messageContent(self, didTapAttachmentForMessage: (cid, message.id))
        }
        
        self.addEmotionButton.didSelect { [unowned self] in
            guard let message = self.message, let cid = message.streamCid else { return }
            self.delegate?.messageContent(self, didTapAddExpressionForMessage: (cid, message.id))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.emotionCollectionView.expandToSuperviewSize()
        
        self.emotionLabel.setSize(withWidth: self.width)
        self.emotionLabel.centerOnXAndY()
        
        self.addEmotionImageView.squaredSize = 20
        self.addEmotionImageView.pin(.right, offset: .long)
        self.addEmotionImageView.pin(.bottom, offset: .long)

        self.addEmotionButton.squaredSize = 44
        self.addEmotionButton.pin(.bottom)
        self.addEmotionButton.pin(.right)

        self.blurView.expandToSuperviewSize()

        self.mainContentArea.pin(.left, offset: MessageContentView.padding)
        self.mainContentArea.pin(.top, offset: MessageContentView.padding)
        self.mainContentArea.expand(.right, padding: MessageContentView.padding.value)
        self.mainContentArea.expand(.bottom, padding: MessageContentView.padding.value)

        // Author and Emoji
        self.authorView.setSize(forHeight: MessageContentView.authorViewHeight)
        self.authorView.pin(.top)
        self.authorView.pin(.left)
        
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
        
        self.countCircle.match(.top, to: .top, of: self.imageView, offset: .short)
        self.countCircle.match(.right, to: .right, of: self.imageView, offset: .negative(.short))
        self.countCircle.showShadow(withOffset: 2)
        
        self.videoImageView.squaredSize = 16
        self.videoImageView.match(.bottom, to: .bottom, of: self.imageView, offset: .negative(.short))
        self.videoImageView.match(.right, to: .right, of: self.imageView, offset: .negative(.short))
        self.videoImageView.showShadow(withOffset: 2)
    }

    private var linkProvider: LPMetadataProvider?

    func configure(with message: Messageable) {
        // True we're changing what message to display
        let isDifferentMessage = self.message?.id != message.id

        self.message = message

        self.textView.isVisible = message.kind.hasText && !message.kind.isLink
        self.imageView.isVisible = message.kind.hasImage
        self.linkView.isVisible = message.kind.isLink
        self.videoImageView.isVisible = message.kind.hasVideo
        self.countCircle.isVisible = false

        self.dateView.configure(with: message)
        self.deliveryView.image = message.deliveryType.image

        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)

            switch message.kind {
            case .photo(photo: let photo, _):
                // Only reload the picture if it's actually a new message.

                if isDifferentMessage || self.imageView.imageView.image.isNil {
                    if let previewURL = photo.previewURL {
                        self.imageView.displayable = previewURL
                    } else {
                        self.imageView.displayable = photo.url
                    }
                }
            case .video(video: let video, _):
                
                if isDifferentMessage || self.imageView.imageView.image.isNil {
                    if let previewURL = video.previewURL {
                        self.imageView.displayable = previewURL
                    } else {
                        self.imageView.displayable = video.url
                    }
                }
                
            case .media(items: let media, _):
                if isDifferentMessage || self.imageView.imageView.image.isNil {
                    if let previewURL = media.first?.previewURL {
                        self.imageView.displayable = previewURL
                    } else {
                        self.imageView.displayable = media.first?.url
                    }
                    
                    self.countCircle.set(count: media.count)
                    self.countCircle.isVisible = true
                }
                
            case .link(url: let url, _):
                guard isDifferentMessage || url != self.linkView.metadata.originalURL else { break }

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
            case .text, .attributedText, .location, .emoji, .audio, .contact:
                self.imageView.isVisible = false
                self.linkView.isVisible = false
                break
            }
        }
        
        self.loadExpressions(for: message)
    }
    
    /// The currently running task that is loading the expressions.
    private var loadTask: Task<Void, Never>?
    
    private func loadExpressions(for message: Messageable) {
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            if let info = message.authorExpression,
               let expression = try? await Expression.getObject(with: info.expressionId) {
                let emotionCounts = expression.emotionCounts 
                // Only animate changes to the emotion when they're not blurred out.
                let isAnimated = self.areEmotionsShown

                if isAnimated {
                    self.emotionLabel.alpha = emotionCounts.isEmpty ? 0.2 : 0.0
                }
                self.emotionCollectionView.setEmotionsCounts(emotionCounts, animated: isAnimated)

                self.authorView.set(info: info, author: message.authorId)
            } else if let author = await PeopleStore.shared.getPerson(withPersonId: message.authorId){
                self.authorView.set(displayable: author)
                self.authorView.set(emotionCounts: [:])
            }
            
            self.setNeedsLayout()
        }
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: UIColor,
                             textColor: UIColor,
                             brightness: CGFloat,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.textView.textColor = textColor
        self.textView.linkTextAttributes = [.foregroundColor: ThemeColor.D6.color, .underlineStyle: 0]

        self.bubbleView.setBubbleColor(color.withAlphaComponent(brightness), animated: false)
        self.bubbleView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.bubbleView.orientation = tailOrientation
    }

    func playReadAnimations() async {
        await self.textView.startReadAnimation()
        await UIView.awaitAnimation(with: .custom(1)) {
            self.imageView.alpha = 1
            self.linkView.alpha = 1
        }
    }

    func setEmotions(areShown: Bool, animated: Bool) {
        if !areShown {
            self.blurView.alpha = 1
        }

        let animationDuration = animated ? Theme.animationDurationStandard : 0
        UIView.animate(withDuration: animationDuration) {
            self.mainContentArea.alpha = areShown ? 0 : 1
            self.blurView.effect = areShown ? nil : Theme.blurEffect

            if areShown {
                if self.emotionCollectionView.emotionCounts.count == 0 {
                    self.emotionLabel.alpha = 0.2
                } else {
                    self.emotionLabel.alpha = 0.0
                }
                
                // Only allow the author to add emotions
                if let msg = self.message, msg.isFromCurrentUser, msg.authorExpression.isNil {
                    self.addEmotionImageView.alpha = 1.0
                    self.addEmotionButton.alpha = 1.0
                }
    
            } else {
                self.addEmotionButton.alpha = 0.0
                self.addEmotionImageView.alpha = 0.0
                self.emotionLabel.alpha = 0.0
            }
        } completion: { completed in
            if areShown {
                // Set the blur view alpha to 0 so it doesn't interfere with touches.
                self.blurView.alpha = 0
            }
        }
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
