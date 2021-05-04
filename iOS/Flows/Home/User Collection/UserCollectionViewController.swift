//
//  FeedCollectionViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserCollectionViewController: CollectionViewController<UserCollectionViewManger.SectionType, UserCollectionViewManger> {

    static let height: CGFloat = 100

    private let gradientView = GradientView(with: [Color.background1.color.withAlphaComponent(0.6).cgColor,
                                                   Color.background1.color.withAlphaComponent(0).cgColor], startPoint: .topCenter, endPoint: .bottomCenter)

    var statusView: FeedStatusView? {
        guard let cv = self.collectionViewManager.collectionView as? UserCollectionView else { return nil }
        return cv.statusView
    }

    override func getCollectionView() -> CollectionView {
        return UserCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        RitualManager.shared.$state
            .mainSink { state in
            switch state {
            case .feedAvailable:
                self.collectionViewManager.loadFeeds()
            default:
                self.collectionViewManager.reset()
            }
        }.store(in: &self.cancellables)

        self.view.insertSubview(self.gradientView, belowSubview: self.collectionViewManager.collectionView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.gradientView.expandToSuperviewSize()
    }
}
