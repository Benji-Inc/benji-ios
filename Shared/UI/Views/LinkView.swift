//
//  LinkView.swift
//  Ours
//
//  Created by Benji Dodgson on 6/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SDWebImageLinkPlugin

class LinkView: DisplayableImageView {

    private let linkView = LPLinkView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.imageView.removeFromSuperview()
        self.insertSubview(self.linkView, belowSubview: self.blurView)

        self.linkView.contentMode = .scaleAspectFit
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.linkView.expandToSuperviewSize()
    }

    override func updateImageView(with displayable: ImageDisplayable) {
        self.state = .loading

        if let result = displayable.textResult {
            self.downloadAndSet(result: result)
        } else {
            self.showResult(for: nil)
        }
    }

    private func downloadAndSet(result: NSTextCheckingResult) {
        guard let url = result.url else {
            self.showResult(for: nil)
            return
        }

        self.linkView.sd_setImage(with: url) { [weak self] linkImage, error, linkCache, linkURL in
            guard let `self` = self else { return }
            self.showResult(for: linkImage)
        }
    }
}
