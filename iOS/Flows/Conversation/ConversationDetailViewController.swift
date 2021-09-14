//
//  ConversationDetailBar.swift
//  Benji
//
//  Created by Benji Dodgson on 7/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization
import Combine
import StreamChat

@MainActor
protocol ConversationDetailViewControllerDelegate: AnyObject {
    func conversationDetailViewControllerDidTapMenu(_ vc: ConversationDetailViewController)
}

class ConversationDetailViewController: ViewController {

    enum State: CGFloat {
        case collapsed = 84
        case expanded = 340
    }

    var state: State = .collapsed
    @Published var isHandlingTouches: Bool = false

    private let stackedAvatarView = StackedAvatarView()
    private let textView = TextView()
    private let label = Label(font: .displayUnderlined, textColor: .purple)

    lazy var animator = UIViewPropertyAnimator(duration: 2.0, curve: .linear, animations: nil)

    unowned let delegate: ConversationDetailViewControllerDelegate
    private var conversation: DisplayableConversation?
    private var channelController: ChatChannelController?

    init(conversation: DisplayableConversation?, delegate: ConversationDetailViewControllerDelegate) {
        self.conversation = conversation
        self.delegate = delegate

        super.init()

        if let conversation = conversation {
            switch conversation.conversationType {
            case .system(let systemConversation):
                break
            case .conversation(let chatChannel):
                self.channelController = chatClient.channelController(for: chatChannel.cid)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Because this animator is interruptable and is stopped by the completion event of another animation,
        // we need to ensure that this gets called before the animator is cleaned up when this view is deallocated
        // because there's no guarantee that will happen before a user dismisses the screen
        self.animator.stopAnimation(true)
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.stackedAvatarView)
        self.view.addSubview(self.textView)
        self.textView.alpha = 0
        self.textView.isScrollEnabled = false 
        self.view.addSubview(self.label)
        self.label.alpha = 0

        self.subscribeToConversationUpdates()
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
        self.textView.match(.top, to: .bottom, of: self.label, offset: Theme.contentOffset.half)
    }

    private func subscribeToConversationUpdates() {
        guard let channel = self.channelController?.channel else { return }

        self.layoutViews(for: channel)
    }

    private func layoutViews(for conversation: ChatChannel) {
        let members = conversation.lastActiveMembers.filter { member in
            return member.id != chatClient.currentUserId
        }
        self.layout(members: members, conversation: conversation)
    }

    private func layout(members: [ChatChannelMember], conversation: ChatChannel) {
        let date = conversation.createdAt

        self.stackedAvatarView.set(items: members)
        let message: Localized
        if members.count == 0 {
            message = "No one has joined yet."
            // No one in the conversation but the current user.
        } else if members.count == 1, let member = members.first {
            self.label.setText(member.fullName)
            message = self.getMessage(for: member, date: date, conversation: conversation)
        } else {
            // Group chat
            message = self.getMessage(for: members, date: date, conversation: conversation)
        }

        let attributed = AttributedString(message,
                                          fontType: .small,
                                          color: .background4)
        self.textView.set(attributed: attributed, linkColor: .teal)
        delay(0.1) { [unowned self] in
            self.view.layoutNow()
        }
    }

    func createAnimator() {
        self.animator.addAnimations { [weak self] in
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
        }

        if !self.animator.scrubsLinearly {
            self.animator.scrubsLinearly = true
        }

        if !self.animator.isInterruptible {
            self.animator.isInterruptible = true
        }

        if !self.animator.pausesOnCompletion {
            self.animator.pausesOnCompletion = true
        }
        
        self.animator.pauseAnimation()
    }

    private func getMessage(for member: ChatChannelMember, date: Date, conversation: ChatChannel) -> LocalizedString {
        var author = ""
        if conversation.isOwnedByMe {
            author = "You"
        } else {
            author = member.givenName
        }

        return LocalizedString(id: "", arguments: [member.givenName, author, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your direct message history with [@(name)](userid). @(author) created this conversation on @(date)")
    }

    private func getMessage(for members: [ChatChannelMember], date: Date, conversation: ChatChannel) -> LocalizedString {
        var text = ""
        for (index, user) in members.enumerated() {
            if index < members.count - 1 {
                text.append(String("\(user.givenName), "))
            } else if index == members.count - 1 && members.count > 1 {
                text.append(String("\(user.givenName)"))
            } else {
                text.append(user.givenName)
            }
        }

        var author = ""
        if conversation.isOwnedByMe {
            author = "You"
        } else if let member = members.first {
            author = member.givenName
        }

        return LocalizedString(id: "", arguments: [text, author, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your group chat with [@(name)](userid). @(author) created this conversation on @(date)")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isHandlingTouches = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHandlingTouches = false
    }
}
