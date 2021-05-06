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

class DisplayableImageView: View {

    private(set) var imageView = UIImageView()
    private(set) var cancellables = Set<AnyCancellable>()

    lazy var blurEffect = UIBlurEffect(style: .systemMaterialDark)
    lazy var blurView = BlurView(effect: self.blurEffect)

    lazy var loadingIndicator = UIActivityIndicatorView(style: .medium)

    let symbolImageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))

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
        self.blurView.contentView.addSubview(self.loadingIndicator)
        self.loadingIndicator.hidesWhenStopped = true

        self.blurView.contentView.addSubview(self.symbolImageView)
        self.symbolImageView.tintColor = Color.white.color
        self.symbolImageView.contentMode = .scaleAspectFit
        self.symbolImageView.alpha = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()

        self.loadingIndicator.centerOnXAndY()

        self.symbolImageView.squaredSize = self.blurView.width * 0.25
        self.symbolImageView.centerOnXAndY()
    }

    private func updateImageView(with displayable: ImageDisplayable) {
        self.symbolImageView.alpha = 0.0
        self.loadingIndicator.startAnimating()

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

        self.symbolImageView.alpha = 0.0
        self.displayable = nil
        self.loadingIndicator.stopAnimating()
        self.blurView.effect = self.blurEffect
    }

    private func showResult(for image: UIImage?) {

        UIView.animate(withDuration: 0.2) {
            self.symbolImageView.alpha = image.isNil ? 1.0 : 0.0
            self.blurView.effect = image.isNil ? self.blurEffect : nil
        }

        self.loadingIndicator.stopAnimating()
        self.imageView.image = image
    }
}
