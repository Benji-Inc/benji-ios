//
//  FeedCollectionView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class UserCollectionView: CollectionView {

    let statusView = FeedStatusView()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(layout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.backgroundView = self.statusView

        self.publisher(for: \.contentSize).mainSink { (size) in
            self.statusView.alpha = size.width > 0.0 && !self.animationView.isAnimationPlaying ? 0.0 : 1.0
        }.store(in: &self.cancellables)

        self.bounces = true
        self.set(backgroundColor: .clear)
        self.showsHorizontalScrollIndicator = false
    }
}
