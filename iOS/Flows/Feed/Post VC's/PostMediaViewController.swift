//
//  PostMediaViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostMediaViewController: PostViewController {

    private let imageView = UIImageView()

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.imageView, at: 0)
        self.imageView.contentMode = .scaleToFill
    }

    override func configurePost() {
        super.configurePost()

        guard let file = self.post.file else { return }

        file.getDataInBackground { data, error in
            if let data = data, let image = UIImage(data: data) {
                self.imageView.image = image
            }
        } progressBlock: { progress in
            print(progress)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
    }
}
