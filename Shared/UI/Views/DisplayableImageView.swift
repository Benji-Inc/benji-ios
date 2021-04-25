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

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.frame = self.bounds
    }

    private func updateImageView(with displayable: ImageDisplayable) {
        if let photo = displayable.image {
            self.imageView.image = photo
            self.didDisplayImage?(photo)
        } else if let objectID = displayable.userObjectID {
            self.findUser(with: objectID)
        } else if let url = displayable.url {
            self.downloadAndSetImage(url: url)
        }
    }

    private func downloadAndSetImage(for user: User) {
        user.smallImage?.getDataInBackground { (imageData: Data?, error: Error?) in
            guard let data = imageData, let image = UIImage(data: data) else { return }
            self.imageView.image = image
            self.didDisplayImage?(image)
        }
    }

    private func findUser(with objectID: String) {
        User.localThenNetworkQuery(for: objectID)
            .mainSink(receiveValue: { (user) in
                self.downloadAndSetImage(for: user)
            }).store(in: &self.cancellables)
    }

    private func downloadAndSetImage(url: URL) {
        self.imageView.sd_setImage(with: url, completed: { [weak self] (image, error, imageCacheType, imageUrl) in
            guard let `self` = self, let downloadedImage = image else { return }
            self.imageView.image = downloadedImage
            self.didDisplayImage?(downloadedImage)
        })
    }
}
