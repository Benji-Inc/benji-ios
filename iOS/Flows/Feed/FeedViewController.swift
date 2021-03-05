//
//  HomeStackViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

protocol FeedViewControllerDelegate: AnyObject {
    func feedView(_ controller: FeedViewController, didSelect item: PostType)
}

class FeedViewController: ViewController {

    lazy var manager: FeedManager = {
        let manager = FeedManager(with: self, delegate: self)
        return manager
    }()

    weak var delegate: FeedViewControllerDelegate?

    private let reloadButton = Button()
    lazy var indicatorView = FeedIndicatorView(with: self)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.reloadButton)

        self.reloadButton.alpha = 0
        self.view.addSubview(self.indicatorView)
        self.indicatorView.alpha = 0

        self.reloadButton.set(style: .normal(color: .purple, text: "Reload"))
        self.reloadButton.didSelect { [unowned self] in
            self.reloadFeed()
        }
    }

    private func loadFeed() {
//        if let ritual = User.current()?.ritual {
//            ritual.retrieveDataIfNeeded()
//                .mainSink(receivedResult: { (result) in
//                    switch result {
//                    case .success(let r):
//                        self.subscribeToRitualUpdates()
//                        self.determineMessage(with: r)
//                    case .error(_):
//                        //self.state = .noRitual
//                        self.addFirstItems()
//                    }
//                }).store(in: &self.cancellables)
//        } else {
//           // self.state = .noRitual
//            self.addFirstItems()
//        }
    }

    private func subscribeToRitualUpdates() {

        RitualManager.shared.$state.mainSink { state in
            switch state {
            case .noRitual:
                break
            default:
                break
            }
        }.store(in: &self.cancellables)

//        User.current()?.ritual?.subscribe()
//            .mainSink(receiveValue: { (event) in
//                switch event {
//                case .created(let r), .updated(let r):
//                    self.determineMessage(with: r)
//                case .deleted(_):
//                    self.addFirstItems()
//                default:
//                    break
//                }
//            }).store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.reloadButton.size = CGSize(width: 140, height: 40)
        self.reloadButton.centerOnXAndY()

        self.indicatorView.size = CGSize(width: self.view.width - 20, height: 2)
        self.indicatorView.pinToSafeArea(.top, padding: 0)
        self.indicatorView.centerOnX()
    }

    func showReload() {
        //self.messageLabel.setText("You are all caught up!\nSee you tomorrow 🤗")
        self.view.bringSubviewToFront(self.reloadButton)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration, delay: Theme.animationDuration, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 1
            self.indicatorView.alpha = 0
        }, completion: { _ in })
    }

    private func reloadFeed() {
        self.view.sendSubviewToBack(self.reloadButton)
        UIView.animate(withDuration: Theme.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 0
            self.indicatorView.alpha = 1
            self.indicatorView.resetAllIndicators()
        }, completion: { completed in
            self.manager.showFirst()
        })
    }

    func showFeed() {
        UIView.animate(withDuration: Theme.animationDuration, delay: 0, options: [], animations: {
            self.indicatorView.alpha = 1
            self.reloadButton.alpha = 0
        }, completion: nil)
    }
}
