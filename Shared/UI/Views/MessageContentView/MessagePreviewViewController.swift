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
    private let emotionView = EmotionView()
    private let replyView = MessageReplyView()

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
        self.view.addSubview(self.replyView)
        self.replyView.set(backgroundColor: .clear)
        
        self.view.addSubview(self.readView)
        self.readView.set(backgroundColor: .clear)
        
        self.view.addSubview(self.emotionView)
        
        self.view.set(backgroundColor: .L1)

        self.content.state = .expanded
        self.content.configureBackground(color: ThemeColor.clear.color,
                                         textColor: ThemeColor.T2.color,
                                         brightness: 0.0,
                                         focusAmount: 0,
                                         showBubbleTail: false,
                                         tailOrientation: .up)
        self.content.configure(with: self.message)
        self.content.bubbleView.backgroundLayer.fillColor = ThemeColor.clear.color.cgColor
        self.content.bubbleView.lightGradientLayer.opacity = 0.0
        
        if let msg = self.message as? Message {
            self.replyView.setReplies(for: msg)
            self.replyView.countLabel.setTextColor(.T2)
            self.replyView.height = 25
            self.readView.showRead(with: msg)
            self.readView.label.setTextColor(.T2)
            self.emotionView.configure(for: msg)
            self.emotionView.label.setTextColor(.T2)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.content.size = self.content.getSize(for: .expanded, with: self.view.width)
        self.content.width = self.view.width
        self.content.centerOnX()
        self.content.pin(.top)
        
        self.replyView.right = self.view.width - Theme.ContentOffset.standard.value
        self.replyView.pin(.bottom, offset: .standard)
        
        self.readView.height = 25
        if self.replyView.width > 0 {
            self.readView.match(.right, to: .left, of: self.replyView, offset: .negative(.short))
        } else {
            self.readView.match(.right, to: .left, of: self.replyView, offset: .noOffset)
        }
        self.readView.match(.bottom, to: .bottom, of: self.replyView)
        
        self.emotionView.height = 25
        self.emotionView.pin(.left, offset: .long)
        self.emotionView.match(.bottom, to: .bottom, of: self.replyView)
    }
}
