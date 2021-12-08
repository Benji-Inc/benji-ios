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

        self.view.set(backgroundColor: .red)
        self.view.addSubview(self.content)

        self.content.state = .expanded
        self.content.configureBackground(color: .white, brightness: 1.0, showBubbleTail: false, tailOrientation: .up)
        self.content.configure(with: self.message)

        let maxWidth = Theme.getPaddedWidth(with: window.width)
        var size = self.content.getSize(for: .expanded, with: maxWidth)

        if size.width < maxWidth {
            size.width = maxWidth
        }

        if size.height < MessageContentView.bubbleHeight {
            size.height = MessageContentView.bubbleHeight
        }

        self.content.size = size

        self.preferredContentSize = size 
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.content.centerOnX()
        self.content.pin(.bottom)
    }
}
