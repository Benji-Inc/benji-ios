//
//  WalletHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletHeaderView: UICollectionReusableView {
    
    private let topLeftDetailView = DetailView(shouldPinLeft: true)
    private let bottomLeftDetailView = DetailView(shouldPinLeft: true)
    private let topRightDetailView = DetailView(shouldPinLeft: false)
    private let bottomRightDetailView = DetailView(shouldPinLeft: false)
    
    private let imageView = UIImageView(image: UIImage(named: "jiblogo"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.topLeftDetailView)
        self.addSubview(self.bottomLeftDetailView)
        self.addSubview(self.topRightDetailView)
        self.addSubview(self.bottomRightDetailView)
        self.addSubview(self.imageView)
    }
    
    func configure(with transactions: [WalletCollectionViewDataSource.ItemType]) {
        
        self.topLeftDetailView.configure(with: "Jibs", subtitle: "Reward Credits")
        self.bottomLeftDetailView.configure(with: "Jibber", subtitle: "Member since 2022")
        self.topRightDetailView.configure(with: "0.0", subtitle: "Total Earnings")
        self.bottomRightDetailView.configure(with: "$0.00", subtitle: "Credit Balance")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.topLeftDetailView.pin(.left)
        self.topLeftDetailView.pin(.top, offset: .custom(20))
        
        self.bottomLeftDetailView.pin(.bottom)
        self.bottomLeftDetailView.pin(.left)
        
        self.topRightDetailView.pin(.right)
        self.topRightDetailView.pin(.top, offset: .custom(20))
        
        self.bottomRightDetailView.pin(.right)
        self.bottomRightDetailView.pin(.bottom)
        
        self.imageView.squaredSize = 100
        self.imageView.centerOnXAndY()
        self.imageView.centerY += 10
    }
}

private class DetailView: BaseView {
    let titleLabel = ThemeLabel(font: .medium)
    let subtitleLabel = ThemeLabel(font: .regular, textColor: .D1)
    private let shouldPinLeft: Bool
    
    init(shouldPinLeft: Bool) {
        self.shouldPinLeft = shouldPinLeft
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
    }
    
    func configure(with title: String,
                   subtitle: String) {
        
        self.titleLabel.setText(title)
        self.titleLabel.textAlignment = self.shouldPinLeft ? .left : .right
        self.subtitleLabel.setText(subtitle)
        self.subtitleLabel.textAlignment = self.shouldPinLeft ? .left : .right
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: 200)
        self.subtitleLabel.setSize(withWidth: 200)
        
        self.height = self.titleLabel.height + Theme.ContentOffset.standard.value + self.subtitleLabel.height
        self.width = self.titleLabel.width > self.subtitleLabel.width ? self.titleLabel.width : self.subtitleLabel.width
        
        if self.shouldPinLeft {
            self.titleLabel.pin(.left)
            self.subtitleLabel.pin(.left)
        } else {
            self.titleLabel.pin(.right)
            self.subtitleLabel.pin(.right)
        }
        
        self.titleLabel.pin(.top)
        self.subtitleLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .standard)
    }
}
