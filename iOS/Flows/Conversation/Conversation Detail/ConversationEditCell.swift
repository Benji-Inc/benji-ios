//
//  ConversationEditCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationEditCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = ChannelId
    
    var currentItem: ChannelId?
    
    private let label = ThemeLabel(font: .regular, textColor: .D6)
    private let lineView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.label)
        self.label.setText("Edit")
        
        self.contentView.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B5)
        self.lineView.alpha = 0.1
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.pin(.top)
    }
}
