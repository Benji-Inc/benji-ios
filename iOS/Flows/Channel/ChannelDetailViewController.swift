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
import Combine

protocol ChannelDetailViewControllerDelegate: class {
    func channelDetailViewControllerDidTapMenu(_ vc: ChannelDetailViewController)
}

class ChannelDetailViewController: ViewController {

    enum State: CGFloat {
        case collapsed = 84
        case expanded = 400
    }

    var state: State = .collapsed

    private let stackedAvatarView = StackedAvatarView()
    private let textView = TextView()
    private let label = Label(font: .displayUnderlined, textColor: .purple)

    private(set) var animator: UIViewPropertyAnimator?

    unowned let delegate: ChannelDetailViewControllerDelegate

    init(delegate: ChannelDetailViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        // Because this animator is interruptable and is stopped by the completion event of another animation, we need to ensure that this gets called before the animator is cleaned up when this view is deallocated because theres no guarantee that will happen before a user dismisses the screen
        self.animator?.stopAnimation(true)
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.stackedAvatarView)
        self.view.addSubview(self.textView)
        self.textView.alpha = 0
        self.view.addSubview(self.label)
        self.label.alpha = 0

        self.subscribeToUpdates()
        self.createAnimator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.view.height = self.state.rawValue

        let proposedHeight = self.state.rawValue - 20
        let stackedHeight = clamp(proposedHeight, 60, 180)
        self.stackedAvatarView.itemHeight = stackedHeight
        self.stackedAvatarView.pin(.left, padding: Theme.contentOffset)
        self.stackedAvatarView.pin(.top, padding: Theme.contentOffset)

        let maxWidth = self.view.width - (Theme.contentOffset * 2)
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.left, padding: Theme.contentOffset)
        self.label.match(.top, to: .bottom, of: self.stackedAvatarView, offset: Theme.contentOffset)

        self.textView.setSize(withWidth: maxWidth)
        self.textView.left = Theme.contentOffset
        self.textView.match(.top, to: .bottom, of: self.label, offset: Theme.contentOffset)
    }

    private func subscribeToUpdates() {

        ChannelSupplier.shared.$activeChannel.mainSink { [weak self] (channel) in
            guard let `self` = self, let activeChannel = channel else { return }
            switch activeChannel.channelType {
            case .channel(let channel):
                self.layoutViews(for: channel)
            default:
                break
            }
        }.store(in: &self.cancellables)
    }

    private func layoutViews(for channel: TCHChannel) {
        channel.getUsers(excludeMe: true)
            .mainSink { (users) in
                self.stackedAvatarView.set(items: users)
            }.store(in: &self.cancellables)

        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (members) in
                if let first = members.first, let date = channel.dateCreatedAsDate {
                    self.label.setText(first.handle)
                    let message = self.getMessage(handle: first.fullName, date: date)
                    let attributed = AttributedString(message,
                                                      fontType: .small,
                                                      color: .background4)
                    self.textView.set(attributed: attributed, linkColor: .teal)
                }

                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }

    func createAnimator() {
        guard self.animator.isNil else { return }

        self.animator = UIViewPropertyAnimator(duration: 2.0, curve: .linear, animations: { [weak self] in
            guard let `self` = self else { return }
            UIView.animateKeyframes(withDuration: 0.0,
                                    delay: 0.0,
                                    options: .calculationModeLinear) {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: 1.0) {
                    self.state = .expanded
                    self.view.layoutNow()
                }

                UIView.addKeyframe(withRelativeStartTime: 0.5,
                                   relativeDuration: 0.25) {
                    self.label.alpha = 1
                }

                UIView.addKeyframe(withRelativeStartTime: 0.75,
                                   relativeDuration: 0.25) {
                    self.textView.alpha = 1
                }

                } completion: { (completed) in}
        })

        self.animator?.scrubsLinearly = true
        self.animator?.isInterruptible = true

        self.animator?.pausesOnCompletion = true
    }

    private func getMessage(handle: String, date: Date) -> LocalizedString {
        return LocalizedString(id: "", arguments: [handle, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your direct message history with [@(name)](userid). You created this conversation on @(date)")
    }
}
