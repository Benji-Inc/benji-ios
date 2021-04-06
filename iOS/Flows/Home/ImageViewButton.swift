//
//  HomeAddButton.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ImageViewButton: View {

    let imageView = UIImageView()
    var didSelect: CompletionOptional = nil

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = Color.background4.color
        self.imageView.contentMode = .scaleAspectFit

        self.didSelect { [unowned self] in
            self.didSelect?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.size = CGSize(width: self.width * 0.55, height: self.height * 0.55)
        self.imageView.centerOnXAndY()

        self.imageView.layer.shadowColor = Color.background1.color.cgColor
        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.imageView.layer.shadowRadius = 10
        self.imageView.layer.masksToBounds = false
    }
}
