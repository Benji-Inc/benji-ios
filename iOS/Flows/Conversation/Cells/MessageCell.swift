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
    let detailView = MessageDetailView()

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
        self.contentView.addSubview(self.detailView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //let host = UIHostingController(rootView: ())
        //self.parentViewController()?.addChild(viewController: host, toView: <#T##UIView?#>)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.detailView.expandToSuperviewWidth()
        self.content.expandToSuperviewWidth()

        self.content.height = self.bounds.height - (self.detailView.height - (self.content.bubbleView.tailLength - Theme.ContentOffset.standard.value))

        if self.content.bubbleView.orientation == .down {
            self.content.pin(.top)
            self.detailView.pin(.bottom)
        } else if self.content.bubbleView.orientation == .up {
            self.detailView.pin(.top)
            self.content.pin(.bottom)
        }
    }

    func configure(with message: Messageable) {
        self.content.configure(with: message)
        self.detailView.configure(with: message)

        self.setNeedsLayout()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }
        
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         brightness: 1.0, //TODO
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)

        self.detailView.height = MessageDetailView.height
        self.detailView.alpha = messageLayoutAttributes.detailAlpha

        self.content.state = messageLayoutAttributes.state
        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.detailView.updateReadStatus(shouldRead: messageLayoutAttributes.detailAlpha == 1.0)
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
