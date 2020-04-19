//
//  ChannelViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ReactiveSwift
import Parse
import TwilioChatClient
import TMROFutures

typealias ChannelViewControllerDelegates = ChannelDetailBarDelegate & ChannelViewControllerDelegate

protocol ChannelViewControllerDelegate: class {
    func channelView(_ controller: ChannelViewController, didTapShare message: Messageable)
}

class ChannelViewController: FullScreenViewController, ActiveChannelAccessor {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    lazy var detailBar = ChannelDetailBar(delegate: self.delegate)
    lazy var collectionView = ChannelCollectionView()
    lazy var collectionViewManager = ChannelCollectionViewManager(with: self.collectionView)
    private(set) var messageInputView = MessageInputView()

    let disposables = CompositeDisposable()

    // A Boolean value that determines whether the `MessagesCollectionView`
    /// maintains it's current position when the height of the `MessageInputBar` changes.
    ///
    /// The default value of this property is `false`.
    var maintainPositionOnKeyboardFrameChanged: Bool = false
    private var animateMessages: Bool = true
    private var bottomOffset: CGFloat {
        var offset: CGFloat = 6
        if let handler = self.keyboardHandler, handler.currentKeyboardHeight == 0 {
            offset += self.view.safeAreaInsets.bottom
        }
        return offset
    }

    var previewAnimator: UIViewPropertyAnimator?
    var previewView: PreviewMessageView?
    var interactiveStartingPoint: CGPoint?

    unowned let delegate: ChannelViewControllerDelegates

    init(delegate: ChannelViewControllerDelegates) {
        self.delegate = delegate
        super.init()
    }

    deinit {
        self.disposables.dispose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(withObject object: DeepLinkable) {
        fatalError("init(withObject:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.registerKeyboardEvents()

        self.view.addSubview(self.blurView)
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.detailBar)

        self.view.addSubview(self.messageInputView)
        self.messageInputView.height = self.messageInputView.minHeight

        self.collectionView.dataSource = self.collectionViewManager
        self.collectionView.delegate = self.collectionViewManager

        self.messageInputView.onPanned = { [unowned self] (panRecognizer) in
            self.handle(pan: panRecognizer)
        }

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputView.textView.isFirstResponder {
                self.messageInputView.textView.resignFirstResponder()
            }
        }

        if let activeChannel = self.activeChannel {
            self.load(activeChannel: activeChannel)
        }

        self.disposables.add(ChannelSupplier.shared.activeChannel.producer.on { [unowned self] (channel) in
            guard let activeChannel = channel else {
                self.collectionView.activityIndicator.startAnimating()
                self.collectionViewManager.reset()
                return
            }

            self.load(activeChannel: activeChannel)
        }.start())

        self.collectionViewManager.didTapShare = { [unowned self] message in
            self.delegate.channelView(self, didTapShare: message)
        }

        self.subscribeToClient()
    }

    private func load(activeChannel: DisplayableChannel) {
        switch activeChannel.channelType {
        case .system(_):
            break
        case .channel(let channel):
            channel.delegate = self
            self.loadMessages(for: activeChannel.channelType)
            self.messageInputView.setPlaceholder(with: channel)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if MessageSupplier.shared.sections.count > 0 {
            self.collectionViewManager.set(newSections: MessageSupplier.shared.sections,
                                           animate: self.animateMessages) {
                                            self.animateMessages = false
            }
        } else {
            MessageSupplier.shared.didGetLastSections = { [unowned self] sections in
                self.collectionViewManager.set(newSections: sections,
                                               animate: self.animateMessages) {
                                                self.animateMessages = false
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        guard let handler = self.keyboardHandler else { return }

        self.detailBar.size = CGSize(width: self.view.width - (Theme.contentOffset * 2), height: 84)
        self.detailBar.top = Theme.contentOffset
        self.detailBar.centerOnX()

        let keyboardHeight = handler.currentKeyboardHeight
        let height = self.view.height - keyboardHeight

        self.collectionView.size = CGSize(width: self.view.width, height: height)
        self.collectionView.top = 0
        self.collectionView.centerOnX()

        self.messageInputView.width = self.view.width - Theme.contentOffset * 2
        var messageBottomOffset: CGFloat = 10
        if keyboardHeight == 0, let window = UIWindow.topWindow() {
            messageBottomOffset += window.safeAreaInsets.bottom
        }

        self.messageInputView.bottom = self.collectionView.bottom - messageBottomOffset
        self.messageInputView.centerOnX()
    }

    override func viewWasDismissed() {
        super.viewWasDismissed()

        ChannelSupplier.shared.set(activeChannel: nil)
        self.collectionViewManager.reset()
    }

    func send(message: String,
              context: MessageContext = .casual,
              attributes: [String : Any]) {

        guard let channelDisplayable = ChannelSupplier.shared.activeChannel.value,
            let current = User.current(),
            let objectId = current.objectId else { return }

        var mutableAttributes = attributes
        mutableAttributes["updateId"] = UUID().uuidString

        let systemMessage = SystemMessage(avatar: current,
                                          context: context,
                                          text: message,
                                          isFromCurrentUser: true,
                                          createdAt: Date(),
                                          authorId: objectId,
                                          messageIndex: nil,
                                          status: .sent,
                                          id: String(),
                                          attributes: mutableAttributes)

        self.collectionViewManager.append(item: systemMessage) { [unowned self] in
            self.collectionView.scrollToEnd()
        }

        switch channelDisplayable.channelType {
        case .system(_):
            break
        case .channel(let channel):
            ChannelManager.shared.sendMessage(to: channel,
                                              with: message,
                                              context: context,
                                              attributes: mutableAttributes)
        }

        self.messageInputView.reset()
    }
}

extension ChannelViewController: TCHChannelDelegate {

    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    member: TCHMember,
                    updated: TCHMemberUpdate) {
        print("Channel Member updated")
    }

    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    message: TCHMessage,
                    updated: TCHMessageUpdate) {
        
        self.collectionViewManager.updateItem(with: message)
    }
}
