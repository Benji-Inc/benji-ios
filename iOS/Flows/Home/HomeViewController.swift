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
import Intents

class HomeViewController: CollectionViewController<HomeCollectionViewManager.SectionType, HomeCollectionViewManager>, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    let addButton = Button()

    var isMenuPresenting: Bool = false

    override func initializeViews() {
        super.initializeViews()

//        INFocusStatusCenter.default.requestAuthorization { status in
//            switch status {
//
//            case .notDetermined:
//                break
//            case .restricted:
//                break
//            case .denied:
//                break
//            case .authorized:
//                break
//            @unknown default:
//                break
//            }
//        }

        ConnectionsManager.shared.$userUpdated.mainSink { user in
            guard let u = user else { return }
            print("FOCUS: \(String(describing: u.focusStatus))")
        }.store(in: &self.cancellables)

        self.view.set(backgroundColor: .background1)

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

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.centerOnX()
        self.addButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    func animate(show: Bool) {
        self.isMenuPresenting = !show
        UIView.animate(withDuration: Theme.animationDuration) {
            self.collectionViewManager.collectionView.alpha = show ? 1.0 : 0.0
        }
    }
}
