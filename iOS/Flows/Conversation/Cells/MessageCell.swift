//
//  MessageCell.swift
//  Jibber
//
//  Created by Martin Young on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI
import StreamChat

/// A cell for displaying individual messages, author and reactions.
class MessageCell: UICollectionViewCell {

    let content = MessageContentView()

    // Detail View
    @ObservedObject private var messageState = MessageDetailConfig(message: nil)
    private lazy var detailView = MessageDetailView(config: self.messageState)
    private lazy var detailVC = NavBarIgnoringHostingController(rootView: self.detailView)
    var shouldShowDetailBar: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.content)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        self.detailVC.removeFromParentAndSuperviewIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if self.window.exists {
            self.parentViewController()?.addChild(viewController: self.detailVC,
                                                  toView: self.contentView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.height = 25

        self.content.expandToSuperviewWidth()
        self.content.height
        = self.bounds.height - (self.detailVC.view.height - (self.content.bubbleView.tailLength - Theme.ContentOffset.standard.value))

        if self.content.bubbleView.orientation == .down {
            self.content.pin(.top)
            self.detailVC.view.pin(.bottom)
        } else if self.content.bubbleView.orientation == .up {
            self.detailVC.view.pin(.top)
            self.content.pin(.bottom)
        }
    }

    func configure(with message: Messageable) {
        self.content.configure(with: message)

        self.messageState.message = message
        
        self.detailVC.view.isVisible = self.shouldShowDetailBar

        self.setNeedsLayout()
    }

    private var consumeMessageTask: Task<Void, Never>?

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }
        
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         textColor: messageLayoutAttributes.textColor,
                                         brightness: messageLayoutAttributes.brightness,
                                         focusAmount: messageLayoutAttributes.sectionFocusAmount,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)

        self.content.state = messageLayoutAttributes.state
        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.detailVC.view.height = old_MessageDetailView.height
        self.detailVC.view.alpha = messageLayoutAttributes.detailAlpha

        let isAtTop = messageLayoutAttributes.detailAlpha == 1.0 && self.shouldShowDetailBar
        if isAtTop {
            self.handleConsumption()
        } else {
            self.consumeMessageTask?.cancel()
        }
    }

    func handleConsumption() {
        guard ChatUser.currentUserRole != .anonymous,
              let message = self.messageState.message,
              message.canBeConsumed else {
                  return
              }

        self.consumeMessageTask?.cancel()
        self.consumeMessageTask = Task {
            logDebug("starting consumption of: "+message.kind.text)

            await Task.snooze(seconds: 2)

            guard !Task.isCancelled else {
                logDebug("consumption was cancelled")
                return
            }

            try? await message.setToConsumed()

            logDebug("finished consumption of: "+message.kind.text)
        }
    }
}

extension UIView {
    
    // HACK: Accessing a parent view controller from a view is an anti-pattern, but it's extremely convenient
    // in this case where we're assigning a view controller to a cell and need to add it as a childVC.

    /// Used to get the parent view controller of a collection view cell
    fileprivate func parentViewController() -> UIViewController? {
        
        guard let nextResponder = self.next else { return nil }
        
        if let parentViewController = nextResponder as? UIViewController {
            return parentViewController
        } else if let parentView = nextResponder as? UIView {
            return parentView.parentViewController()
        } else {
            return nil;
        }
    }
}
