//
//  AddReactionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AddReactionView: UICollectionReusableView {

    let imageView = DisplayableImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {
        self.addSubview(self.imageView)
        self.imageView.displayable = UIImage(systemName: "face.smiling")
        self.imageView.imageView.tintColor = Color.gray.color
        self.imageView.imageView.contentMode = .scaleAspectFit
        self.imageView.isVisible = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 20
        self.imageView.centerOnXAndY()
    }
}
