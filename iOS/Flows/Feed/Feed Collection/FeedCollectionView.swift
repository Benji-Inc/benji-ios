//
//  FeedCollectionView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class FeedCollectionView: CollectionView {

    let emptyView = FeedEmptyView()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(layout: layout)

        self.backgroundView = self.emptyView
        self.emptyView.alpha = 0

        self.publisher(for: \.contentSize).mainSink { (size) in
            self.emptyView.alpha = size.width > 0.0 ? 0.0 : 1.0
        }.store(in: &self.cancellables)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.bounces = false
        self.set(backgroundColor: .clear)
        self.showsHorizontalScrollIndicator = false
    }
}

class FeedEmptyView: View {

}
