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
    private let textView = ExpandingTextView()
    private let imageView = DisplayableImageView()
    @Published var messageKind: MessageKind?
    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.textView)
        self.addSubview(self.imageView)

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
            case .link(let url):
                self.textView.text = url.absoluteString
            }
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewWidth()
        self.imageView.pin(.top)
        self.imageView.height = self.imageView.displayable.isNil ? 0 : 100
        self.imageView.centerOnX()
        
        self.textView.setSize(withMaxWidth: self.width)
        self.textView.centerOnX()
        self.textView.match(.top, to: .bottom, of: self.imageView)
    }
}
