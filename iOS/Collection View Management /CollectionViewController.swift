//
//  CollectionViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CollectionViewController<SectionType: ManagerSectionType,
                               ManagerType: CollectionViewManager<SectionType>>: ViewController {

    private var collectionView: CollectionView!
    lazy var collectionViewManager = ManagerType(with: self.collectionView)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensures the collectionView gets set
        self.collectionView = self.getCollectionView()

        // Adding the collection view in viewDidLoad so that it's ensured to be the bottom most view
        self.view.addSubview(self.collectionViewManager.collectionView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionViewManager.collectionView.expandToSuperviewSize()
    }

    func getCollectionView() -> CollectionView {
        fatalError()
    }
}
