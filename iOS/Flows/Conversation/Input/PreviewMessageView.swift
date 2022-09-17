//
//  PreviewMessageView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PreviewMessageView: SpeechBubbleView {

    private let minHeight: CGFloat = 52
    let textView = ExpandingTextView()
    private let imageView = DisplayableImageView()
    private let countCircle = CircleCountView() 
    private let deliveryTypeView = MessageDeliveryTypeBadgeView()

    var deliveryType: MessageDeliveryType? {
        get {
            return self.deliveryTypeView.deliveryType
        }
        set {
            self.deliveryTypeView.deliveryType = newValue
            self.setNeedsLayout()
        }
    }
    @Published var messageKind: MessageKind?

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.tailLength = 0

        self.addSubview(self.textView)
        self.textView.textAlignment = .left
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.addSubview(self.imageView)

        self.imageView.layer.borderColor = ThemeColor.whiteWithAlpha.color.cgColor
        self.imageView.layer.borderWidth = 2
        self.imageView.layer.masksToBounds = true
        self.imageView.layer.cornerRadius = Theme.innerCornerRadius
        
        self.imageView.addSubview(self.countCircle)

        self.addSubview(self.deliveryTypeView)
        // Start the delivery type invisible so it doesn't briefly flicker on screen.
        self.deliveryTypeView.alpha = 0

        self.$messageKind.mainSink { [unowned self] (kind) in
            guard let messageKind = kind else { return }

            self.countCircle.isVisible = false
            
            switch messageKind {
            case .text(let body):
                self.textView.text = body
            case .attributedText(let body):
                self.textView.text = body.string
            case .photo(photo: let photo, body: let body):
                self.textView.text = body
                self.imageView.displayable = photo.image
            case .video(video: let video, body: let body):
                self.textView.text = body
                self.imageView.displayable = video.previewURL
            case .media(items: let media, body: let body):
                self.textView.text = body
                if let first = media.first {
                    switch first.type {
                    case .photo:
                        if let data = first.data {
                            self.imageView.displayable = UIImage(data: data)
                        } else {
                            self.imageView.displayable = first.url
                        }
                    case .video:
                        self.imageView.displayable = media.first?.previewURL
                    }
                }
                
                self.countCircle.set(count: media.count)
                self.countCircle.isVisible = true 
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .link(_, let stringURL):
                self.textView.text = stringURL
            }
            
            self.imageView.isVisible = self.imageView.displayable.exists

            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 34

        let maxWidth: CGFloat
        = self.width - self.imageView.width - Theme.ContentOffset.standard.value.doubled

        self.imageView.pin(.right, offset: .standard)
        self.imageView.pin(.bottom, offset: .standard)
        
        self.textView.setSize(withMaxWidth: maxWidth, maxHeight: self.height + Theme.ContentOffset.standard.value.doubled)
        self.textView.pin(.left, offset: .standard)
        self.textView.center.y = self.halfHeight

        self.deliveryTypeView.centerOnX()
        self.deliveryTypeView.pin(.top, offset: .custom(-self.deliveryTypeView.halfHeight - 4))
        
        self.countCircle.pin(.bottom, offset: .short)
        self.countCircle.pin(.right, offset: .short)
    }
}
