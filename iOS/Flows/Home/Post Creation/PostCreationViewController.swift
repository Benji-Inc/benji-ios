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

    let vibrancyView = PostVibrancyView()
    let exitButton = ImageViewButton()

    var didTapExit: CompletionOptional = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.didCapturePhoto = { [unowned self] image in
            self.show(image: image)
        }

        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.exitButton)

        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.alpha = 0
        self.exitButton.didSelect { [unowned self] in
            self.didTapExit?()
            self.reset()
           // self.tabView.state = .home
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.vibrancyView.animateScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.vibrancyView.expandToSuperviewSize()

        self.exitButton.squaredSize = 50
        self.exitButton.match(.top, to: .top, of: self.vibrancyView, offset: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)
    }

    func handle(state: HomeTabView.State) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.exitButton.alpha = state == .home ? 0.0 : 1.0
            self.vibrancyView.show(blur: state == .home)
        }
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
