//
//  ConversationPreviewViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 1/22/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationPreviewViewController: ViewController {

    let channel: DisplayableConversation
    let channelSize: CGSize

    private let content = ConversationContentView()

    init(with channel: DisplayableConversation, size: CGSize) {
        self.channel = channel
        self.channelSize = size
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.content)
        self.content.configure(with: self.channel)
        self.preferredContentSize = self.channelSize
        self.view.set(backgroundColor: .background1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
