//
//  PostViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 2/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostViewController: ViewController {

    let type: PostType

    var didFinish: CompletionOptional = nil
    var didSkip: CompletionOptional = nil

    let container = View()
    let textView = FeedTextView()
    let avatarView = AvatarView()
    let button = Button()

    init(with type: PostType) {
        self.type = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.container)
        self.container.addSubview(self.textView)
        self.container.addSubview(self.avatarView)
        self.container.addSubview(self.button)
        self.button.didSelect { [unowned self] in
            self.didTapButton()
        }
    }

    func didTapButton() {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let margin = Theme.contentOffset * 2
        self.container.size = CGSize(width: self.view.width - margin, height: self.view.height - margin)
        self.container.centerOnXAndY()

        if let first = self.container.subviews.first {
            first.frame = self.container.bounds
        }

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.pin(.top, padding: self.container.height * 0.3)

        self.textView.setSize(withWidth: self.container.width * 0.9)
        self.textView.centerOnX()
        self.textView.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset)

        self.button.setSize(with: self.container.width)
        self.button.centerOnX()
        self.button.pin(.bottom, padding: -Theme.contentOffset)
    }
}
