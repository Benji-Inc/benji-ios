//
//  HomeTabView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeTabView: View {

    private(set) var postButtonView = PostButtonView()
    private var leftButton = ImageViewButton()
    private var rightButton = ImageViewButton()
    private var cancellables = Set<AnyCancellable>()

    var didSelectPhotoLibrary: CompletionOptional = nil
    var didSelectFlip: CompletionOptional = nil
    var didSelectProfile: CompletionOptional = nil
    var didSelectChannels: CompletionOptional = nil

    enum State {
        case home
        case capture
        case review
        case confirm
    }

    @Published var state: State = .home

    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.leftButton)
        self.addSubview(self.postButtonView)
        self.addSubview(self.rightButton)

        self.$state.mainSink { state in
            self.handle(state: state)
        }.store(in: &self.cancellables)

        self.leftButton.didSelect { [unowned self] in
            switch self.state {
            case .home:
                self.didSelectProfile?()
            case .capture:
                self.didSelectPhotoLibrary?()
            case .review, .confirm:
                break
            }
        }

        self.rightButton.didSelect { [unowned self] in
            switch self.state {
            case .home:
                self.didSelectChannels?()
            case .capture:
                self.didSelectFlip?()
            case .review, .confirm:
                break
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let topPadding: CGFloat = 20

        let itemWidth = self.width * 0.33
        let itemSize = CGSize(width: itemWidth, height: 60)
        self.leftButton.size = itemSize
        self.leftButton.pin(.top, padding: topPadding)
        self.leftButton.left = 0

        self.postButtonView.size = itemSize
        self.postButtonView.pin(.top)
        self.postButtonView.left = self.leftButton.right

        self.rightButton.size = itemSize
        self.rightButton.pin(.top, padding: topPadding)
        self.rightButton.left = self.postButtonView.right
    }

    private func handle(state: State) {
        switch state {
        case .home:
            self.leftButton.imageView.image = UIImage(systemName: "person.crop.circle")
            self.leftButton.alpha = 1
            self.rightButton.imageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
            self.rightButton.alpha = 1
        case .capture:
            self.leftButton.imageView.image = UIImage(systemName: "square.grid.2x2")!
            self.leftButton.alpha = 1
            self.rightButton.imageView.image = UIImage(systemName: "arrow.triangle.2.circlepath")!
            self.rightButton.alpha = 1
        case .review:
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0 
        case .confirm:
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0 
        }

        self.postButtonView.update(for: state)
    }
}
