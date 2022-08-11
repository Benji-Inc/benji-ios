//
//  MomentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct MomentViewModel: Hashable {
    var date: Date
    var momentId: String?
}

class MomentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = MomentViewModel
    
    var currentItem: MomentViewModel?
    let label = ThemeLabel(font: .regularBold)
    let videoView = VideoView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.videoView.shouldPlay = true
        
        self.contentView.addSubview(self.videoView)
        
        self.contentView.layer.cornerRadius = Theme.innerCornerRadius
        self.contentView.layer.masksToBounds = true
        
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    func configure(with item: MomentViewModel) {
        
        self.label.text = ""
        
        if let daysAgo = Date.today.subtract(component: .day, amount: 14), item.date.isBetween(Date.today, and: daysAgo) {
            self.label.setText("\(item.date.day)")
        } else if item.date.isSameDay(as: Date.today) {
            self.label.setText("\(item.date.day)")
        }
        
        Task {
            if let previewURL = try? await Moment.getObject(with: item.momentId).preview?.retrieveCachedPathURL() {
                self.videoView.videoURL = previewURL
            }
        }
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.videoView.expandToSuperviewSize()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.label.text = ""
        self.videoView.videoURL = nil 
    }
}
