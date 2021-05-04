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

class HomeViewController: ViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    lazy var feedCollectionVC = UserCollectionViewController()
    lazy var createVC = PostCreationViewController()
    lazy var archivesVC = ArchivesViewController()

    let tabView = HomeTabView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil
    var didTapAddRitual: CompletionOptional = nil
    var didSelectPhotoLibrary: CompletionOptional = nil

    var willPresentFeedForUser: ((User) -> Void)? = nil

    var topOffset: CGFloat?
    var minTop: CGFloat {
        return UserCollectionViewController.height + self.view.safeAreaInsets.top
    }

    var minBottom: CGFloat {
        return self.view.height
    }

    var isPanning: Bool = false
    var isMenuPresenting: Bool = false
    var isShowingArchive = false

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.addChild(viewController: self.feedCollectionVC)
        self.addChild(viewController: self.archivesVC)
        self.addChild(viewController: self.createVC)

        self.self.createVC.view.layer.cornerRadius = 20
        self.createVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.createVC.view.layer.masksToBounds = true

        self.view.addSubview(self.tabView)

        self.tabView.didSelectProfile = { [unowned self] in
            self.didTapProfile?()
        }

        self.tabView.postButtonView.button.didSelect { [unowned self] in
            self.didTapPost()
        }

        self.tabView.didSelectChannels = { [unowned self] in
            self.didTapChannels?()
        }

        self.tabView.didSelectFlip = { [unowned self] in
            self.createVC.flipCamera()
        }

        self.tabView.didSelectPhotoLibrary = { [unowned self] in
            self.didSelectPhotoLibrary?()
        }

        self.feedCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard !self.isPanning, let user = cellItem?.item as? User else { return }
            if self.isShowingArchive {
                self.archivesVC.loadPosts(for: user)
            } else {
                self.willPresentFeedForUser?(user)
            }

        }.store(in: &self.cancellables)

        self.tabView.$state.mainSink { state in
            self.createVC.handle(state: state)
            UIView.animate(withDuration: Theme.animationDuration) {
                self.view.layoutNow()
            }
        }.store(in: &self.cancellables)

        self.createVC.didShowImage = { [unowned self] in 
            self.tabView.state = .review
        }

        self.createVC.shouldHandlePan = { [unowned self] pan in
            pan.delegate = self
            self.handle(pan)
        }

        self.createVC.didTapExit = {
            self.tabView.state = .home
        }

        self.archivesVC.didSelectClose = { [unowned self] in
            switch RitualManager.shared.state {
            case .feedAvailable:
                self.feedCollectionVC.collectionViewManager.unselectAllItems()
            default:
                self.feedCollectionVC.collectionViewManager.reset()
            }
            self.animateArchives(offset: self.minTop, progress: 1.0)
        }

        self.archivesVC.didFinishShowing = { [unowned self] in
            if self.feedCollectionVC.collectionViewManager.collectionView.numberOfSections == 0 {
                self.feedCollectionVC.collectionViewManager.loadFeeds { [unowned self] in
                    self.feedCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
                }
            } else {
                self.feedCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
            }
        }

        if self.createVC.isAuthorized {
            self.createVC.begin()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.feedCollectionVC.view.expandToSuperviewWidth()
        self.feedCollectionVC.view.height = UserCollectionViewController.height
        self.feedCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.archivesVC.view.frame = self.createVC.view.frame
        self.archivesVC.view.height = self.view.height - self.minTop
        self.archivesVC.view.expandToSuperviewWidth()
        self.archivesVC.view.centerOnX()
        self.archivesVC.view.pin(.top, padding: self.minTop)

        if self.tabView.state == .home {
            self.createVC.view.height = self.archivesVC.view.height
        } else {
            self.createVC.view.height = self.view.height - self.view.safeAreaInsets.top
        }
        self.createVC.view.expandToSuperviewWidth()
        self.createVC.view.centerOnX()

        if self.topOffset.isNil {
            if self.tabView.state == .home {
                self.createVC.view.pin(.top, padding: self.minTop)
            } else {
                self.createVC.view.pinToSafeArea(.top, padding: 0)
            }
        }

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        if self.tabView.state == .review {
            self.tabView.match(.top, to: .bottom, of: self.createVC.view)
        } else {
            self.tabView.match(.bottom, to: .bottom, of: self.createVC.view)
        }
    }

    func animate(show: Bool) {
        self.isMenuPresenting = !show
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = show ? 1.0 : 0.0
            self.feedCollectionVC.view.alpha = show ? 1.0 : 0.0
        }
    }

    func animateArchives(offset: CGFloat, progress: CGFloat) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.createVC.view.top = offset
            self.view.layoutNow()
        } completion: { completed in
            self.isShowingArchive = progress < 0.65
            self.archivesVC.animate(show: self.isShowingArchive)
        }
    }

    private func didTapPost() {
        switch self.tabView.state {
        case .home:

            if !self.createVC.session.isRunning {
                self.createVC.begin()
            }
            
            self.topOffset = nil
            self.tabView.state = .capture

            if self.createVC.vibrancyView.animationView.isAnimationPlaying {
                self.createVC.vibrancyView.animationView.stop()
            }
            
        case .capture:
            self.createVC.capturePhoto()
        case .review:
            break
        case .confirm:
            break
        }
    }
}
