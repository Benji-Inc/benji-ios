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

    init(with type: PostType) {
        self.type = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
