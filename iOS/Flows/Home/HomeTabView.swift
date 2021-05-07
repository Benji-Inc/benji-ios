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
            self.didSelectProfile?()
        }

        self.rightButton.didSelect { [unowned self] in
            self.didSelectChannels?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let itemWidth = self.width * 0.33
        let itemSize = CGSize(width: itemWidth, height: 60)
        self.leftButton.size = itemSize
        if self.safeAreaInsets.bottom == 0 {
            self.leftButton.pin(.bottom, padding: 0)
        } else  {
            self.leftButton.pinToSafeArea(.bottom, padding: 0)
        }
        self.leftButton.left = 0

        self.postButtonView.size = itemSize
        self.postButtonView.pin(.top)
        self.postButtonView.left = self.leftButton.right

        self.rightButton.size = itemSize
        if self.safeAreaInsets.bottom == 0 {
            self.rightButton.pin(.bottom, padding: 0)
        } else  {
            self.rightButton.pinToSafeArea(.bottom, padding: 0)
        }
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
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0
        case .review:
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0 
        case .confirm:
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0 
        }

        self.postButtonView.update(for: state)
        self.layoutNow()
    }
}
