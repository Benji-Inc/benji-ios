//
//  ConnectionCell.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionCell: CollectionViewManagerCell {

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.set(backgroundColor: .red)
    }

    func configure(with connection: Connection) {
        
    }
    
}
