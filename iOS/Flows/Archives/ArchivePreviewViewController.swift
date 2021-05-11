//
//  ArchivePreviewViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 5/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivePreviewViewController: ViewController {

    let post: Post
    let size: CGSize

    //private let content = ChannelContentView()

    init(with post: Post, size: CGSize) {
        self.post = post
        self.size = size
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        //self.view.addSubview(self.content)
       // self.content.configure(with: self.channel)
        self.preferredContentSize = self.size
        self.view.set(backgroundColor: .red)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        //self.content.expandToSuperviewSize()
    }
}
