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

    lazy var noticesCollectionVC = NoticesCollectionViewController()
    lazy var userCollectionVC = UserCollectionViewController()
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
        return NoticesCollectionViewController.height + self.view.safeAreaInsets.top
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

        self.addChild(viewController: self.archivesVC)
        //self.addChild(viewController: self.userCollectionVC)
        self.addChild(viewController: self.noticesCollectionVC)
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

        self.createVC.didSelectLibrary = { [unowned self] in
            self.didSelectPhotoLibrary?()
        }

        self.userCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
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

        self.createVC.didShowMedia = { [weak self] in
            guard let `self` = self else { return }
            self.tabView.state = .review
        }

        self.createVC.shouldHandlePan = { [weak self] pan in
            guard let `self` = self else { return }
            pan.delegate = self
            self.handle(pan)
        }

        self.createVC.didTapExit = { [unowned self] in 
            self.tabView.state = .home
        }

        self.archivesVC.didSelectClose = { [unowned self] in
            switch RitualManager.shared.state {
            case .feedAvailable:
                self.userCollectionVC.collectionViewManager.unselectAllItems()
            default:
                self.userCollectionVC.collectionViewManager.reset()
            }
            self.animateArchives(offset: self.minTop, progress: 1.0)
        }

        self.archivesVC.didFinishShowing = { [unowned self] in
            if self.userCollectionVC.collectionViewManager.collectionView.numberOfSections == 0 {
                self.userCollectionVC.collectionViewManager.loadFeeds { [unowned self] in
                    self.userCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
                }
            } else {
                self.userCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
            }
        }

        if self.createVC.isAuthorized {
            self.createVC.begin()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.noticesCollectionVC.view.expandToSuperviewWidth()
        self.noticesCollectionVC.view.height = NoticesCollectionViewController.height
        self.noticesCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.userCollectionVC.view.expandToSuperviewWidth()
        self.userCollectionVC.view.height = UserCollectionViewController.height
        self.userCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.archivesVC.view.height = self.view.height - self.view.safeAreaInsets.top
        self.archivesVC.view.expandToSuperviewWidth()
        self.archivesVC.view.centerOnX()
        self.archivesVC.view.pinToSafeArea(.top, padding: 0)

        if self.tabView.state == .home {
            self.createVC.view.height = self.view.height - self.minTop
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
            self.userCollectionVC.view.alpha = show ? 1.0 : 0.0
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
