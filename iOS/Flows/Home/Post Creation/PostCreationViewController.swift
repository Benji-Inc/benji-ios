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

    // Add future 
    func createPost() {
        guard let image = self.imageView.image, let data = image.data else { return }
        FeedManager.shared.createPost(with: data)
            .mainSink { post in
                self.reset()
            }.store(in: &self.cancellables)
    }

    func reset() {
        self.imageView.image = nil
        self.begin()
    }
}
