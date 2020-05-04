//
//  ChannelDetailBar.swift
//  Benji
//
//  Created by Benji Dodgson on 7/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import TMROLocalization
import ReactiveSwift

protocol ChannelDetailViewControllerDelegate: class {
    func channelDetailViewControllerDidTapMenu(_ vc: ChannelDetailViewController)
}

class ChannelDetailViewController: ViewController {

    enum State {
        case collapsed
        case expanded
    }

    private lazy var blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
    private lazy var blurView = UIVisualEffectView(effect: self.blurEffect)
    let collapsedHeight: CGFloat = 84
    private let titleButton = Button()
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    private let content = ChannelContentView()
    let disposables = CompositeDisposable()
    private let scrollView = UIScrollView()
    private lazy var purposeVC = PurposeViewController()

    unowned let delegate: ChannelDetailViewControllerDelegate

    var currentState = MutableProperty<State>(.collapsed)

    init(delegate: ChannelDetailViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.disposables.dispose()
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.content)
        self.content.addSubview(self.titleButton)
        self.view.addSubview(self.blurView)
        self.view.addSubview(self.scrollView)
        self.addChild(viewController: self.purposeVC, toView: self.scrollView)

        self.titleButton.didSelect = { [unowned self] in
            if self.currentState.value == .expanded {
                self.currentState.value = .collapsed
            } else {
                self.currentState.value = .expanded
            }
        }

        self.view.roundCorners()

        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.content.expandToSuperviewWidth()
        self.content.top = 0
        self.content.centerOnX()
        self.content.height = self.collapsedHeight

        self.titleButton.frame = self.content.titleLabel.frame

        self.scrollView.expandToSuperviewWidth()
        self.scrollView.top = self.content.bottom
        self.scrollView.height = self.view.height - self.content.height

        let purposeHeight = self.purposeVC.getHeight(for: self.scrollView.width)
        self.scrollView.contentSize = CGSize(width: self.scrollView.width,
                                             height: purposeHeight)

        self.purposeVC.view.frame = CGRect(x: 0,
                                           y: 0,
                                           width: self.scrollView.contentSize.width,
                                           height: purposeHeight)

        self.blurView.frame = self.scrollView.frame
    }

    private func subscribeToUpdates() {

        self.disposables.add(ChannelSupplier.shared.activeChannel.producer.on { [unowned self] (channel) in
            guard let activeChannel = channel else { return }
            self.content.configure(with: activeChannel.channelType)
        }.start())

        ChannelManager.shared.channelSyncUpdate.producer.on { [weak self] (update) in
            guard let `self` = self else { return }

            guard let channelsUpdate = update, let activeChannel = ChannelSupplier.shared.activeChannel.value else { return }

            switch activeChannel.channelType {
            case .system(_):
                break
            case .channel(let channel):
                guard channelsUpdate.channel == channel else { return }
                switch channelsUpdate.status {
                case .all:
                    self.content.configure(with: .channel(channelsUpdate.channel))
                default:
                    break
                }
            }
        }.start()
    }
}
