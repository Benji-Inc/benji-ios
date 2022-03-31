//
//  RoomSegmentControlHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/31/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class RoomSegmentControlHeaderView: UICollectionReusableView {
    
    private(set) var segmentControl = ConversationsSegmentControl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.segmentControl)
        self.segmentControl.selectedSegmentIndex = 1 
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let multiplier = self.segmentControl.numberOfSegments < 3 ? 0.5 : 0.333
        let segmentWidth = self.width * multiplier
        self.segmentControl.sizeToFit()
        
        for index in 0...self.segmentControl.numberOfSegments - 1 {
            self.segmentControl.setWidth(segmentWidth, forSegmentAt: index)
        }

        self.segmentControl.expandToSuperviewWidth()
        self.segmentControl.centerOnXAndY()
    }
}
