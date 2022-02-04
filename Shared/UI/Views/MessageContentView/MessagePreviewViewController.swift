//
//  MessagePreviewViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessagePreviewViewController: ViewController {

    let message: Messageable

    private let content = MessageContentView()
    private let readView = MessageReadView()

    init(with message: Messageable) {
        self.message = message
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        guard let window = UIWindow.topWindow() else { return }

        self.view.addSubview(self.content)
        self.view.addSubview(self.readView)

        self.content.state = .expanded
        self.content.configureBackground(color: ThemeColor.L1.color,
                                         textColor: ThemeColor.T2.color,
                                         brightness: 1,
                                         focusAmount: 1,
                                         showBubbleTail: false,
                                         tailOrientation: .up)
        self.content.configure(with: self.message)
        
        if let msg = self.message as? Message {
            self.readView.configure(for: msg)
        }

        let maxWidth = Theme.getPaddedWidth(with: window.width)
        var size = self.content.getSize(for: .expanded, with: maxWidth)

        if size.width < maxWidth {
            size.width = maxWidth
        }

        if size.height < MessageContentView.bubbleHeight {
            size.height = MessageContentView.bubbleHeight
        }
        
        size.height += 25 + Theme.ContentOffset.standard.value.doubled

        self.content.size.width = size.width

        self.preferredContentSize = size 
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let window = UIWindow.topWindow() else { return }

        self.content.size = self.content.getSize(for: .expanded, with: self.view.width)
        self.content.width = self.view.width
        self.content.centerOnX()
        self.content.pin(.top)
        
        self.readView.height = 25
        self.readView.match(.top, to: .bottom, of: self.content, offset: .standard)
        self.readView.pin(.left, offset: .standard)
    }
}
