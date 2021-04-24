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

    lazy var feedCollectionVC = FeedCollectionViewController()
    lazy var captureVC = PostCreationViewController()
    lazy var archivesVC = ArchivesViewController()

    let vibrancyView = HomeVibrancyView()
    let tabView = HomeTabView()
    let exitButton = ImageViewButton()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil
    var didTapAddRitual: CompletionOptional = nil
    var didSelectPhotoLibrary: CompletionOptional = nil

    var willPresentFeed: CompletionOptional = nil

    private var topOffset: CGFloat?
    var minTop: CGFloat {
        return FeedCollectionViewController.height + self.view.safeAreaInsets.top
    }
    private(set) var isPanning: Bool = false
    var isMenuPresenting: Bool = false
    private(set) var isShowingArchive = false

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.addChild(viewController: self.feedCollectionVC)
        self.addChild(viewController: self.archivesVC)
        self.addChild(viewController: self.captureVC)

        self.view.addSubview(self.vibrancyView)

        self.self.captureVC.view.layer.cornerRadius = 20
        self.captureVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.captureVC.view.layer.masksToBounds = true

        self.vibrancyView.layer.cornerRadius = 20
        self.vibrancyView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.vibrancyView.layer.masksToBounds = true

        self.view.addSubview(self.exitButton)
        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.alpha = 0 
        self.exitButton.didSelect { [unowned self] in
            self.captureVC.reset()
            self.tabView.state = .home
        }

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
            self.captureVC.flipCamera()
        }

        self.tabView.didSelectPhotoLibrary = { [unowned self] in
            self.didSelectPhotoLibrary?()
        }

        self.feedCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard !self.isPanning, let user = cellItem?.item as? User else { return }
            FeedManager.shared.selectFeed(for: user)
            if !self.isShowingArchive {
                self.willPresentFeed?()
            }

        }.store(in: &self.cancellables)

        self.tabView.$state.mainSink { state in
            self.exitButton.alpha = state == .home ? 0.0 : 1.0
            self.vibrancyView.show(blur: state == .home)
        }.store(in: &self.cancellables)

        self.captureVC.didShowImage = { [unowned self] in 
            self.tabView.state = .confirm
        }

        self.vibrancyView.onPan { [unowned self] pan in
            pan.delegate = self
            self.handle(pan)
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

        self.captureVC.begin()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.vibrancyView.animateScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.feedCollectionVC.view.expandToSuperviewWidth()
        self.feedCollectionVC.view.height = FeedCollectionViewController.height
        self.feedCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.archivesVC.view.frame = self.captureVC.view.frame
        self.archivesVC.view.height = self.view.height - self.minTop
        self.archivesVC.view.expandToSuperviewWidth()
        self.archivesVC.view.centerOnX()
        self.archivesVC.view.pin(.top, padding: self.minTop)

        self.captureVC.view.height = self.archivesVC.view.height
        self.captureVC.view.expandToSuperviewWidth()
        self.captureVC.view.centerOnX()

        if self.topOffset.isNil {
            self.captureVC.view.pin(.top, padding: self.minTop)
        }

        self.vibrancyView.frame = self.captureVC.view.frame

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.match(.bottom, to: .bottom, of: self.captureVC.view)

        self.exitButton.squaredSize = 50
        self.exitButton.match(.top, to: .top, of: self.vibrancyView, offset: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)
    }

    func animate(show: Bool) {
        self.isMenuPresenting = !show
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = show ? 1.0 : 0.0
            self.feedCollectionVC.view.alpha = show ? 1.0 : 0.0
        }
    }

    private func didTapPost() {
        switch self.tabView.state {
        case .home:
            self.vibrancyView.show(blur: false)
            self.tabView.state = .post
        case .post:
            self.captureVC.capturePhoto()
        case .confirm:
            self.tabView.postButtonView.button.handleEvent(status: .loading)
            self.captureVC.createPost { [unowned self] progress in
                print(progress)
            }.mainSink { result in
                switch result {
                case .success():
                    self.tabView.postButtonView.button.handleEvent(status: .complete)
                    self.tabView.state = .post
                case .error(let e):
                    self.tabView.postButtonView.button.handleEvent(status: .error(e.localizedDescription))
                }
            }.store(in: &self.cancellables)
        }
    }
}

extension HomeViewController: UIGestureRecognizerDelegate {

    private func handle(_ pan: UIPanGestureRecognizer) {
        guard let view = pan.view, !self.isMenuPresenting else {return}

        let translation = pan.translation(in: view.superview)

        switch pan.state {
        case .possible:
            self.isPanning = false
        case .began:
            self.isPanning = false
            self.topOffset = minTop
        case .changed:
            self.isPanning = translation.y > 0
            let newTop = self.minTop + translation.y
            self.topOffset = clamp(newTop, self.minTop, self.view.height)
            self.captureVC.view.top = self.topOffset!
        case .ended, .cancelled, .failed:
            self.isPanning = false
            let diff = (self.view.height - self.minTop) - self.topOffset!
            let progress = diff / (self.view.height - self.minTop)
            self.topOffset = progress < 0.65 ? self.view.height : self.minTop

            self.animateArchives(offset: self.topOffset!, progress: progress)
        @unknown default:
            break
        }

        self.view.layoutNow()
    }

    private func animateArchives(offset: CGFloat, progress: CGFloat) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.captureVC.view.top = offset
            self.view.layoutNow()
        } completion: { completed in
            self.isShowingArchive = progress < 0.65
            self.archivesVC.animate(show: self.isShowingArchive)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let _ = gestureRecognizer as? UIPanGestureRecognizer, self.isMenuPresenting {
            return false
        } else if let _ = gestureRecognizer as? UIScreenEdgePanGestureRecognizer, self.isPanning {
            return false
        }

        return true
    }
}
