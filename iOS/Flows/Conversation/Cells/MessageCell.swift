//
//  MessageCell.swift
//  Jibber
//
//  Created by Martin Young on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

/// A cell for displaying individual messages, author and reactions.
class MessageCell: UICollectionViewCell {

    let content = MessageContentView()

    // Detail View
    @ObservedObject var detailState = MessageDetailConfig()
    lazy var detailView = MessageDetailView(config: self.detailState)
    lazy var detailVC = NavBarIgnoringHostingController(rootView: self.detailView)
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

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if self.detailVC.parent.isNil {
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

        self.detailState.emotion = message.emotion
        self.detailState.isRead = message.isConsumed
        self.detailState.updateDate = message.lastUpdatedAt
        self.detailState.replyCount = message.totalReplyCount
        
        self.detailVC.view.isVisible = self.shouldShowDetailBar

        self.setNeedsLayout()
    }

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
//        let isAtTop = messageLayoutAttributes.detailAlpha == 1.0 && self.shouldShowDetailBar
//        self.detailView.handleTopMessage(isAtTop: isAtTop)
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
