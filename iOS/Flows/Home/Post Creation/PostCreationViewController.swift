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
        self.imageView.contentMode = .scaleAspectFill
        self.didCapturePhoto = { [unowned self] image in
            self.show(image: image)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
    }

    func show(image: UIImage) {
        self.stop()
        self.imageView.image = image
        self.didShowImage?()
    }

    // Add future 
    func createPost(progressHandler: @escaping (Int) -> Void) -> Future<Void, Error> {
        return Future { promise in
            if let image = self.imageView.image, let data = image.data {
                FeedManager.shared.createPost(with: data, progressHandler: progressHandler)
                    .mainSink { post in
                        self.reset()
                        promise(.success(()))
                    }.store(in: &self.cancellables)
            } else {
                promise(.failure(ClientError.apiError(detail: "No image for post")))
            }
        }
    }

    func reset() {
        self.currentPosition = .front
        self.imageView.image = nil
        self.begin()
    }
}
