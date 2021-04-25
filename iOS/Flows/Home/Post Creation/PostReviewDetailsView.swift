//
//  PostReviewDetailsView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostReviewDetailsView: View {

    let imageView = DisplayableImageView()
    let captionTextView = TextView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.addSubview(self.captionTextView)

        self.backgroundColor = .red
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.size = CGSize(width: 100 * 0.74, height: 100)
        self.imageView.pin(.top, padding: Theme.contentOffset)
        self.imageView.pin(.left, padding: Theme.contentOffset)

        let height = self.height - self.imageView.bottom - Theme.contentOffset.half
        self.captionTextView.size = CGSize(width: self.width - Theme.contentOffset.doubled, height: height)
        self.captionTextView.match(.top, to: .bottom, of: self.imageView, offset: Theme.contentOffset.half)
        self.captionTextView.centerOnX()
        
    }
}
