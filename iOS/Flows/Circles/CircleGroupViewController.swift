//
//  CirclesViewController.swift
//  CirclesViewController
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class CircleGroupViewController: DiffableCollectionViewController<CircleGroupCollectionViewDataSource.SectionType, CircleGroupCollectionViewDataSource.ItemType, CircleGroupCollectionViewDataSource> {

    var button = Button()
    var didSelectReservations: CompletionOptional = nil

    init() {
        super.init(with: CollectionView(layout: CircleGroupCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Send Invites"))
        self.button.didSelect { [unowned self] in
            self.didSelectReservations?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()
    }

    // MARK: Data Loading

    override func retrieveDataForSnapshot() async -> [CircleGroupCollectionViewDataSource.SectionType : [CircleGroupCollectionViewDataSource.ItemType]] {

        guard let circles = try? await CircleGroup.query()?.findObjectsInBackground() as? [CircleGroup], !circles.isEmpty else {
            self.collectionView.animationView.stop()
            return [:]
        }

        var data: [CircleGroupCollectionViewDataSource.SectionType : [CircleGroupCollectionViewDataSource.ItemType]] = [:]

        data[.circles] = circles.map({ group in
            return .circles(group)
        })

        return data
    }
}
