//
//  UserStatusView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserStatusView: BaseView {
    
    private let imageView = UIImageView()
    private var currentStatus: FocusStatus?
    
    override func initializeSubviews() {
        self.contentMode = .scaleAspectFill
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        
        self.set(backgroundColor: .white)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.border.color.cgColor
        self.layer.borderWidth = 0.25
        
        self.tintColor = ThemeColor.darkGray.color
        
        self.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
        self.alpha = 0.0
    }
    
    func update(status: FocusStatus) {
        guard status != self.currentStatus else { return }
        
        self.currentStatus = status 
        Task {
            await UIView.awaitAnimation(with: .fast) {
                self.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
                self.alpha = 0.0
            }
            
            if self.currentStatus == .focused {
                self.imageView.image = status.image

                await UIView.awaitSpringAnimation(with: .fast, animations: {
                    self.transform = .identity
                    self.alpha = 1.0
                })
            }
        }.add(to: self.taskPool)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.75
        self.imageView.center.x = self.bounds.size.width * 0.5
        self.imageView.center.y = self.bounds.size.height * 0.5
    }
}
