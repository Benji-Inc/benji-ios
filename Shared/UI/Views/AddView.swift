//
//  AddView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AddView: BaseView {
    
    let imageView = UIImageView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .gray)
        self.addSubview(self.imageView)
        self.imageView.image = UIImage(systemName: "plus")
        self.imageView.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        self.layer.borderColor = ThemeColor.gray.color.cgColor
        self.layer.borderWidth = 2
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.innerCornerRadius
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.5
        self.imageView.centerOnXAndY()
    }
}
