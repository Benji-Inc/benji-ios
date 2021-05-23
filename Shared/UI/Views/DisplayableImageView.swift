//
//  DisplayableImageView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import SDWebImage
import UIKit
import Combine
import Lottie

class DisplayableImageView: View {

    private(set) var imageView = UIImageView()
    private(set) var cancellables = Set<AnyCancellable>()

    lazy var blurEffect = UIBlurEffect(style: .systemMaterialDark)
    lazy var blurView = BlurView(effect: self.blurEffect)

    enum State {
        case initial
        case loading
        case error
        case success
    }

    @Published var state: State = .initial

    let animationView = AnimationView()

    var displayable: ImageDisplayable? {
        didSet {
            guard let displayable = self.displayable else {
                self.showResult(for: nil)
                return
            }

            self.updateImageView(with: displayable)
            self.setNeedsLayout()
        }
    }

    var didDisplayImage: ((UIImage) -> Void)? = nil

    deinit {
        self.reset()
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill

        self.addSubview(self.blurView)
        self.blurView.contentView.addSubview(self.animationView)

        self.$state.mainSink { state in
            switch state {
            case .initial:
                self.reset()
            case .loading:
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
                self.animationView.load(animation: .loading)
                self.animationView.loopMode = .loop
                self.animationView.play()
            case .error:
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
                self.animationView.load(animation: .error)
                self.animationView.loopMode = .playOnce
                self.animationView.play()
            case .success:
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
            }
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()

        self.animationView.squaredSize = 20
        self.animationView.centerOnXAndY()
    }

    private func updateImageView(with displayable: ImageDisplayable) {
        self.state = .loading

        if let photo = displayable.image {
            self.showResult(for: photo)
        } else if let objectID = displayable.userObjectID {
            self.findUser(with: objectID)
        } else if let url = displayable.url {
            self.downloadAndSetImage(url: url)
        } else if let file = displayable as? PFFileObject {
            self.downloadAndSet(file: file)
        }
    }

    private func downloadAndSetImage(for user: User) {
        guard let file = user.smallImage else { return }
        self.downloadAndSet(file: file)
    }

    private func findUser(with objectID: String) {
        User.localThenNetworkQuery(for: objectID)
            .mainSink(receiveValue: { (user) in
                self.downloadAndSetImage(for: user)
            }).store(in: &self.cancellables)
    }

    private func downloadAndSetImage(url: URL) {
        self.imageView.sd_setImage(with: url, completed: { [weak self] (image, error, imageCacheType, imageUrl) in
            guard let `self` = self, let downloadedImage = image else {
                self?.showResult(for: nil)
                return
            }

            self.showResult(for: downloadedImage)
        })
    }

    private func downloadAndSet(file: PFFileObject) {
        file.retrieveDataInBackground { progress in
            // show progress
        }.mainSink { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    self.showResult(for: nil)
                    return
                }

                self.showResult(for: image)

            case .error(_):
                self.showResult(for: nil)
                break
            }
        }.store(in: &self.cancellables)
    }

    func reset() {
        
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }

        self.displayable = nil
        self.animationView.stop()
        self.blurView.effect = self.blurEffect
    }

    private func showResult(for image: UIImage?) {
        self.state = image.isNil ? .error : .success

        UIView.animate(withDuration: 0.2) {
            self.blurView.effect = image.isNil ? self.blurEffect : nil
        }

        self.imageView.image = image
    }
}
