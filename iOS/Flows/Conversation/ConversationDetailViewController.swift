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

    init(delegate: ConversationDetailViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Because this animator is interruptable and is stopped by the completion event of another animation, we need to ensure that this gets called before the animator is cleaned up when this view is deallocated because theres no guarantee that will happen before a user dismisses the screen
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
//        ConversationSupplier.shared.$activeConversation.mainSink { [weak self] (conversation) in
//            guard let `self` = self, let activeConversation = conversation else { return }
//            switch activeConversation.conversationType {
//            case .conversation(let conversation):
//                self.layoutViews(for: conversation)
//            default:
//                break
//            }
//        }.store(in: &self.cancellables)
    }

//    private func layoutViews(for conversation: TCHChannel) {
//        Task {
//            guard let users = try? await conversation.getUsers() else { return }
//
//            self.layout(forNonMe: users, conversation: conversation)
//        }
//    }

//    private func layout(forNonMe users: [User], conversation: TCHChannel) {
//        guard let date = conversation.dateCreatedAsDate else { return }
//
//        self.stackedAvatarView.set(items: users)
//        let message: Localized
//        if users.count == 0 {
//            message = "No one has joined yet."
//            // No one in the conversation but the current user.
//        } else if users.count == 1, let user = users.first {
//            self.label.setText(user.fullName)
//            message = self.getMessage(for: user, date: date, conversation: conversation)
//        } else {
//            // Group chat
//            message = self.getMessage(for: users, date: date, conversation: conversation)
//        }
//
//        let attributed = AttributedString(message,
//                                          fontType: .small,
//                                          color: .background4)
//        self.textView.set(attributed: attributed, linkColor: .teal)
//        delay(0.1) { [unowned self] in
//            self.view.layoutNow()
//        }
//    }

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

    #warning("Replace")
//    private func getMessage(for user: User, date: Date, conversation: TCHChannel) -> LocalizedString {
//
//        var author = ""
//        if conversation.isOwnedByMe {
//            author = "You"
//        } else {
//            author = user.givenName
//        }
//
//        return LocalizedString(id: "", arguments: [user.givenName, author, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your direct message history with [@(name)](userid). @(author) created this conversation on @(date)")
//    }
//
//    private func getMessage(for users: [User], date: Date, conversation: TCHChannel) -> LocalizedString {
//
//        var text = ""
//        for (index, user) in users.enumerated() {
//            if index < users.count - 1 {
//                text.append(String("\(user.givenName), "))
//            } else if index == users.count - 1 && users.count > 1 {
//                text.append(String("\(user.givenName)"))
//            } else {
//                text.append(user.givenName)
//            }
//        }
//
//        var author = ""
//        if conversation.isOwnedByMe {
//            author = "You"
//        } else if let user = users.first(where: { user in
//            return user.objectId == conversation.createdBy
//        }) {
//            author = user.givenName
//        }
//
//        return LocalizedString(id: "", arguments: [text, author, Date.monthDayYear.string(from: date)], default: "This is the very beginning of your group chat with [@(name)](userid). @(author) created this conversation on @(date)")
//    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isHandlingTouches = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHandlingTouches = false
    }
}
