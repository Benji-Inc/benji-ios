//
//  CenterViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import Parse
import Combine

class HomeViewController: CollectionViewController<HomeCollectionViewManager.SectionType, HomeCollectionViewManager>, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    let tabView = HomeTabView()
    let addButton = Button()

    var isMenuPresenting: Bool = false

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)
        self.view.addSubview(self.tabView)

        self.view.insertSubview(self.addButton, aboveSubview: self.collectionViewManager.collectionView)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
    }

    override func getCollectionView() -> CollectionView {
        return HomeCollectionView()
    }

    override func viewWasPresented() {
        super.viewWasPresented()

        self.collectionViewManager.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()

        self.tabView.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.pin(.right, padding: Theme.contentOffset)
        self.addButton.pinToSafeArea(.bottom, padding: 0)
    }

    func animate(show: Bool) {
        self.isMenuPresenting = !show
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = show ? 1.0 : 0.0
            self.collectionViewManager.collectionView.alpha = show ? 1.0 : 0.0
        }
    }
}
