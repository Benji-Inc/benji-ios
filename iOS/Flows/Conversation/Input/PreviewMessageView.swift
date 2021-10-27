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
    private let textView = ExpandingTextView()
    private let imageView = DisplayableImageView()
    private(set) var backgroundView = View()
    @Published var messageKind: MessageKind?
    private var cancellables = Set<AnyCancellable>()
    private let triangleView = TriangleView(orientation: .down)

    override var backgroundColor: UIColor? {
        didSet {
            // Ensure that the triangle view is always the same color as the background
            self.triangleView.spikeColor = self.backgroundColor
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        // Don't clip bounds so that the triangle view is visible
        self.clipsToBounds = false
        self.layer.cornerRadius = Theme.cornerRadius
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]

        self.addSubview(self.backgroundView)
        self.addSubview(self.textView)
        self.addSubview(self.imageView)

        self.imageView.clipsToBounds = true

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

        self.addSubview(self.triangleView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundView.expandToSuperviewSize()

        self.imageView.expandToSuperviewWidth()
        self.imageView.pin(.top)
        self.imageView.height = self.imageView.displayable.isNil ? 0 : 100
        self.imageView.centerOnX()
        
        self.textView.width = self.width
        self.textView.height = self.height - self.imageView.height
        self.textView.pin(.left)
        self.textView.match(.top, to: .bottom, of: self.imageView)

        self.triangleView.width = 10
        self.triangleView.height = 8.6
        self.triangleView.centerOnX()
        self.triangleView.top = self.height
    }
}
