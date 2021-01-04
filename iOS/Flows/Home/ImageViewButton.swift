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
        self.imageView.tintColor = Color.white.color
        self.imageView.contentMode = .scaleAspectFit

        self.didSelect { [unowned self] in
            self.didSelect?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.makeRound()

        self.imageView.size = CGSize(width: self.width * 0.55, height: self.height * 0.55)
        self.imageView.centerOnXAndY()
    }
}
