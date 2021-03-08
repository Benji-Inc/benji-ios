//
//  ChannelViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TwilioChatClient
import Combine

typealias ChannelViewControllerDelegates = ChannelDetailViewControllerDelegate & ChannelViewControllerDelegate

protocol ChannelViewControllerDelegate: AnyObject {
    func channelView(_ controller: ChannelViewController, didTapShare message: Messageable)
}

class ChannelViewController: FullScreenViewController, ActiveChannelAccessor {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    lazy var detailVC = ChannelDetailViewController(delegate: self.delegate)
    lazy var collectionView = ChannelCollectionView()
    lazy var collectionViewManager = ChannelCollectionViewManager(with: self.collectionView)

    var indexPathForEditing: IndexPath?

    unowned let delegate: ChannelViewControllerDelegates

    /// A Boolean value that determines whether the `MessagesCollectionView` scrolls to the
    /// last item whenever the `InputTextView` begins editing.
    ///
    /// The default value of this property is `false`.
    /// NOTE: This is related to `scrollToLastItem` whereas the below flag is related to `scrollToBottom` - check each function for differences
    var scrollsToLastItemOnKeyboardBeginsEditing: Bool = false

    /// A Boolean value that determines whether the `MessagesCollectionView` scrolls to the
    /// bottom whenever the `InputTextView` begins editing.
    ///
    /// The default value of this property is `false`.
    /// NOTE: This is related to `scrollToBottom` whereas the above flag is related to `scrollToLastItem` - check each function for differences
    var scrollsToBottomOnKeyboardBeginsEditing: Bool = true

    // A Boolean value that determines whether the `MessagesCollectionView`
    /// maintains it's current position when the height of the `MessageInputBar` changes.
    ///
    /// The default value of this property is `false`.
    var maintainPositionOnKeyboardFrameChanged: Bool = true

    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = self.collectionViewBottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    // Custom Input Accessory View
    lazy var messageInputAccessoryView = InputAccessoryView(with: self)

    override var inputAccessoryView: UIView? {
        // This is a hack to make the input hide during the presentation of the image picker. 
        self.messageInputAccessoryView.alpha = UIWindow.topMostController() == self ? 1.0 : 0.0
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true 
    }

    static var additionalBottomInset: CGFloat = 10

    // Remembers which keyboard a user uses for this conversation.
    override var textInputContextIdentifier: String? {
        return self.activeChannel?.id
    }

    init(delegate: ChannelViewControllerDelegates) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
        self.view.addSubview(self.collectionView)

        self.addChild(viewController: self.detailVC, toView: self.view)

        self.collectionView.dataSource = self.collectionViewManager
        self.collectionView.delegate = self.collectionViewManager

        self.setupHandlers()
        self.subscribeToUpdates()
    }

    private func setupHandlers() {

        self.addKeyboardObservers()

        self.detailVC.$isHandlingTouches.mainSink { isHandlingTouches in
            if isHandlingTouches {
                self.resignFirstResponder()
            } else if !self.isFirstResponder {
                self.becomeFirstResponder()
            }
        }.store(in: &self.cancellables)

        KeyboardManger.shared.$isKeyboardShowing.mainSink { isShowing in                self.detailVC.animator.fractionComplete = self.getDetailProgress()
        }.store(in: &self.cancellables)

        self.collectionViewManager.didTapShare = { [unowned self] message in
            self.delegate.channelView(self, didTapShare: message)
        }

        self.collectionViewManager.didTapResend = { [unowned self] message in
            self.resend(message: message)
        }

        self.collectionViewManager.didTapEdit = { [unowned self] message, indexPath in
            self.indexPathForEditing = indexPath
            self.messageInputAccessoryView.edit(message: message)
        }

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        ChannelSupplier.shared.$activeChannel.mainSink { [unowned self] (channel) in
            guard let activeChannel = channel else {
                self.collectionViewManager.reset()
                return
            }

            self.load(activeChannel: activeChannel)

        }.store(in: &self.cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    override func viewWasDismissed() {
        super.viewWasDismissed()

        MessageSupplier.shared.reset()
        ChannelSupplier.shared.set(activeChannel: nil)
        self.collectionViewManager.reset()
    }

    func setupDetailAnimator() {
        self.detailVC.createAnimator()
        self.collectionView.publisher(for: \.contentOffset)
            .mainSink { (contentOffset) in
                self.detailVC.animator.fractionComplete = self.getDetailProgress()
                self.view.layoutNow()
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.pin(.top)
        self.detailVC.view.centerOnX()

        self.collectionView.expandToSuperviewSize()
    }

    private func getDetailProgress() -> CGFloat {
        guard !KeyboardManger.shared.isKeyboardShowing else { return 0 }

        let threshold = ChannelDetailViewController.State.expanded.rawValue
        let offset = self.collectionView.contentOffset.y + self.collectionView.contentInset.top

        guard offset < threshold else { return 0 }

        let diff = threshold - offset
        let triggerThreshold = (diff / threshold)
        let pullRatio = clamp(triggerThreshold, 0.0, 1.0)
        return pullRatio
    }
}
