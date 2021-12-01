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
        self.imageView.displayable = UIImage(named: "add_reaction")
        self.imageView.imageView.tintColor = Color.white.color.withAlphaComponent(0.8)
        self.imageView.imageView.contentMode = .scaleAspectFit
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 16
        self.imageView.centerOnXAndY()
    }
}
