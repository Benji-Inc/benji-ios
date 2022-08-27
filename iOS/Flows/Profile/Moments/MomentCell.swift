//
//  MomentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie

struct MomentViewModel: Hashable {
    var date: Date
    var momentId: String?
}

class MomentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = MomentViewModel
    
    var currentItem: MomentViewModel?
    let label = ThemeLabel(font: .regularBold)
    let videoView = VideoView()
    let animationView = AnimationView.with(animation: .loading)

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.videoView.shouldPlay = true
        
        self.contentView.addSubview(self.videoView)
        
        self.contentView.layer.cornerRadius = Theme.innerCornerRadius
        self.contentView.layer.masksToBounds = true
        
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0
        
        self.contentView.addSubview(self.animationView)
        self.animationView.loopMode = .loop
    }
    
    func configure(with item: MomentViewModel) {
        
        self.label.alpha = item.momentId.exists ? 0 : 1.0
        self.label.text = ""
        
        if let daysAgo = Date.today.subtract(component: .day, amount: 13), item.date.isBetween(Date.today, and: daysAgo) {
            self.label.setText("\(item.date.day)")
        } else if item.date.isSameDay(as: Date.today) {
            self.label.setText("\(item.date.day)")
        }
        
        Task {
            if let momentId = item.momentId {
                self.animationView.play()
                if let previewURL = try? await Moment.getObject(with: momentId).preview?.retrieveCachedPathURL() {
                    self.videoView.updatePlayer(with: previewURL)
                }
                self.animationView.stop()
            }
            
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.label.alpha = 1
            }
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.videoView.expandToSuperviewSize()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.animationView.size = CGSize(width: 10, height: 10)
        self.animationView.centerOnXAndY()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.animationView.stop()
        self.label.text = ""
        self.videoView.reset()
    }
}
