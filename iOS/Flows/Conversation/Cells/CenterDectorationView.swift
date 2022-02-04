//
//  CenterDectorationView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CenterDectorationView: UICollectionReusableView, ConversationUIStateSettable {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeSubviews() {
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 14
        self.imageView.centerOnXAndY()
    }
    
    func set(state: ConversationUIState) {
        switch state {
        case .read:
            self.imageView.image = UIImage(named: "Collapse")
        case .write:
            self.imageView.image = UIImage(named: "Expand")
        }
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        if let attributes = layoutAttributes as? DecorationViewLayoutAttributes {
            self.set(state: attributes.state)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
