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

    func reset() {
        self.currentPosition = .front
        self.imageView.image = nil
        self.begin()
    }
}
