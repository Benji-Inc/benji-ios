//
//  UserStatusView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserStatusView: UICollectionReusableView {
    
    private let imageView = UIImageView()
    private var currentStatus: FocusStatus?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeSubviews() {
        self.contentMode = .scaleAspectFill
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        
        self.set(backgroundColor: .white)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.border.color.cgColor
        self.layer.borderWidth = 0.25
        
        self.tintColor = ThemeColor.darkGray.color
    }
    
    func update(status: FocusStatus) {
        guard status != self.currentStatus else { return }
        Task {
            await UIView.awaitAnimation(with: .fast) {
                self.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
                self.imageView.alpha = 0.0
            }
            
            self.imageView.image = status.image

            await UIView.awaitSpringAnimation(with: .fast, animations: {
                self.transform = .identity
                self.imageView.alpha = 1.0
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.75
        self.imageView.center.x = self.bounds.size.width * 0.5
        self.imageView.center.y = self.bounds.size.height * 0.5
    }
}
