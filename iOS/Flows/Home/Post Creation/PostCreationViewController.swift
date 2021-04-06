//
//  PostCreationViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PostCreationViewController: ImageCaptureViewController {

    private var cancellables = Set<AnyCancellable>()

    private let imageView = UIImageView()
    var didShowImage: CompletionOptional = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.imageView)

        self.didCapturePhoto = { [unowned self] image in
            self.show(image: image)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
    }

    private func show(image: UIImage) {
        guard let fixed = image.fixedOrientation() else { return }
        self.stop()
        self.imageView.image = fixed
        self.didShowImage?()
    }

    func createPost() {
        guard let data = self.imageView.image?.data else { return }
        Post.create(with: data)
            .mainSink { post in
                self.reset()
            }.store(in: &self.cancellables)
    }

    func reset() {
        self.imageView.image = nil
        self.begin()
    }
}
