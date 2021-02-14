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

    var didSelect: CompletionOptional = nil
    var didSkip: CompletionOptional = nil

    let container = View()

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let margin = Theme.contentOffset * 2
        self.container.size = CGSize(width: self.view.width - margin, height: self.view.height - margin)
        self.container.centerOnXAndY()

        if let first = self.container.subviews.first {
            first.frame = self.container.bounds
        }
    }
}
