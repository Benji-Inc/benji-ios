//
//  FrontPreviewVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FrontPreviewVideoView: VideoPreviewView {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.layer.cornerRadius = self.height * 0.25
    }
}
