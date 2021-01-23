//
//  PreviewMessageView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PreviewMessageView: View {

    private let minHeight: CGFloat = 52
    private let textView = InputTextView()
    private let imageView = DisplayableImageView()
    private(set) var backgroundView = View()
    @Published var sendable: SendableType?
    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.backgroundView)
        self.addSubview(self.textView)
        self.addSubview(self.imageView)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.cornerRadius
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]

        self.$sendable.mainSink { (sendable) in
            guard let sendableType = sendable else { return }

            switch sendableType.kind {
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
            }
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundView.expandToSuperviewSize()

        self.imageView.expandToSuperviewWidth()
        self.imageView.pin(.top)
        self.imageView.height = self.imageView.displayable.isNil ? 0 : 100
        self.imageView.centerOnX()

        self.textView.setSize(withWidth: self.width)
        self.textView.pin(.left)
        self.textView.match(.top, to: .bottom, of: self.imageView)
    }
}
