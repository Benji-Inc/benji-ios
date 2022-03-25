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
    @Published var messageKind: MessageKind?
    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.textView)
        self.textView.textAlignment = .left
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.addSubview(self.imageView)
        
        self.imageView.layer.borderColor = ThemeColor.gray.color.cgColor
        self.imageView.layer.borderWidth = 2
        self.imageView.layer.masksToBounds = true
        self.imageView.layer.cornerRadius = Theme.innerCornerRadius

        self.$messageKind.mainSink { (kind) in
            guard let messageKind = kind else { return }

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
                self.imageView.displayable = video.image
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
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = self.imageView.displayable.isNil ? 0 : 40
        self.imageView.centerOnX()
        self.imageView.pin(.bottom, offset: .custom(24))
        self.imageView.pin(.left, offset: .long)
        
        if self.imageView.displayable.exists {
            let maxWidth: CGFloat = self.width - self.imageView.right - Theme.ContentOffset.long.value
            self.textView.setSize(withMaxWidth: maxWidth, maxHeight: self.height)
            self.textView.match(.left, to: .right, of: self.imageView)
        } else {
            self.textView.setSize(withMaxWidth: self.width, maxHeight: self.height)
            self.textView.pin(.left)
        }
        
        self.textView.center.y = self.halfHeight - 6
    }
}
