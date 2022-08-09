//
//  MembersCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MembersCollectionView: CollectionView {
    
    init() {
        super.init(layout: OrbCollectionViewLayout())
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = .fast
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReveal() {        
        self.alpha = 0

        let visibleCells = self.visibleCells

        for (_, cell) in visibleCells.enumerated() {
            cell.alpha = 0.0
            cell.transform = AnimationPosition.inward.getTransform(for: cell)
        }
    }
    
    func reveal() {
        Task.onMainActorAsync {
            let centerOffsetX = (self.contentSize.width - self.frame.size.width) / 2
            let centerOffsetY = (self.contentSize.height - self.frame.size.height) / 2
            let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
            self.setContentOffset(centerPoint, animated: false)
            
            await Task.sleep(seconds: 0.1)

            await self.animateIn(position: .inward, concatenate: true)
        }
    }
}
