//
//  AttachmentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class AttachmentHeaderView: UICollectionReusableView {
    
    let leftLabel = ThemeLabel(font: .mediumBold)
    let rightLabel = ThemeLabel(font: .mediumBold, textColor: .D1)
    
    let button = ThemeButton()
    
    var didSelectButton: CompletionOptional = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        
        self.addSubview(self.leftLabel)
        self.leftLabel.setText("Photo & Video")
        self.leftLabel.textAlignment = .left

        
        self.addSubview(self.button)
        self.button.didSelect { [unowned self] in
            self.didSelectButton?()
        }
        
        self.addSubview(self.rightLabel)
        self.rightLabel.setText("View Library")
        self.rightLabel.textAlignment = .right
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.leftLabel.setSize(withWidth: self.width)
        self.leftLabel.centerOnY()
        self.leftLabel.pin(.left)
        
        self.rightLabel.setSize(withWidth: self.width)
        self.rightLabel.centerOnY()
        self.rightLabel.pin(.right)
        
        self.button.size = self.rightLabel.size
        self.button.center = self.rightLabel.center 
    }
}
