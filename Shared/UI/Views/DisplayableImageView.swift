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
    private var cancellables = Set<AnyCancellable>()

    lazy var blurEffect = UIBlurEffect(style: .systemMaterialDark)
    lazy var blurView = BlurView(effect: self.blurEffect)

    lazy var loadingIndicator = UIActivityIndicatorView(style: .medium)

    let errorImageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))

    var displayable: ImageDisplayable? {
        didSet {
            guard let displayable = self.displayable else { return }
            self.updateImageView(with: displayable)
            self.setNeedsLayout()
        }
    }

    var didDisplayImage: ((UIImage) -> Void)? = nil

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        self.displayable = UIImage()
        super.init(coder: aDecoder)
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill

        self.addSubview(self.blurView)
        self.blurView.contentView.addSubview(self.loadingIndicator)
        self.loadingIndicator.hidesWhenStopped = true

        self.blurView.contentView.addSubview(self.errorImageView)
        self.errorImageView.tintColor = Color.white.color
        self.errorImageView.contentMode = .scaleAspectFit
        self.errorImageView.alpha = 0.0

        self.imageView.publisher(for: \.image)
            .removeDuplicates()
            .mainSink { image in
                UIView.animate(withDuration: Theme.animationDuration) {
                    self.blurView.effect = image.isNil ? self.blurEffect : nil
                }

                if let img = image {
                    if self.loadingIndicator.isAnimating {
                        self.loadingIndicator.stopAnimating()
                    }
                    self.didDisplayImage?(img)
                }

            }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()

        self.loadingIndicator.centerOnXAndY()

        self.errorImageView.squaredSize = self.blurView.width * 0.25
        self.errorImageView.centerOnXAndY()
    }

    private func updateImageView(with displayable: ImageDisplayable) {
        self.errorImageView.alpha = 0.0
        self.loadingIndicator.startAnimating()

        if let photo = displayable.image {
            self.imageView.image = photo
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
                self?.loadingIndicator.stopAnimating()
                self?.errorImageView.alpha = 1.0
                return
            }

            self.imageView.image = downloadedImage
        })
    }

    private func downloadAndSet(file: PFFileObject) {
        file.retrieveDataInBackground { progress in
            // show progress
        }.mainSink { result in
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    self.loadingIndicator.stopAnimating()
                    self.errorImageView.alpha = 1.0
                    return
                }

                self.imageView.image = image
            case .error(_):
                self.errorImageView.alpha = 1.0
                self.loadingIndicator.stopAnimating()
                break
            }
        }.store(in: &self.cancellables)
    }
}
