//
//  AttachmentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SectionHeaderView: UICollectionReusableView {
    
    let leftLabel = ThemeLabel(font: .regular)
    let rightLabel = ThemeLabel(font: .regular, textColor: .D1)
    
    let button = ThemeButton()
    
    var didSelectButton: CompletionOptional = nil
    
    let lineView = BaseView()
    
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
        self.leftLabel.textAlignment = .left

        
        self.addSubview(self.button)
        self.button.didSelect { [unowned self] in
            self.didSelectButton?()
        }
        
        self.addSubview(self.rightLabel)
        self.rightLabel.textAlignment = .right
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .white)
        self.lineView.alpha = 0.1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.leftLabel.setSize(withWidth: self.width)
        self.leftLabel.centerOnY()
        self.leftLabel.pin(.left, offset: .standard)
        
        self.rightLabel.setSize(withWidth: self.width)
        self.rightLabel.centerOnY()
        self.rightLabel.pin(.right, offset: .standard)
        
        self.button.size = self.rightLabel.size
        self.button.center = self.rightLabel.center
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.pin(.bottom)
    }
}
