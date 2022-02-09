//
//  TransactionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TransactionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Transaction
    
    var currentItem: Transaction?
    
    let avatarView = BorderedAvatarView()
    let titleLabel = ThemeLabel(font: .small)
    let noteLabel = ThemeLabel(font: .regular)
    let amountLabel = ThemeLabel(font: .regular)
    let lineView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.alpha = 0.35
        self.titleLabel.textAlignment = .left
        self.contentView.addSubview(self.noteLabel)
        self.noteLabel.textAlignment = .left
        self.contentView.addSubview(self.amountLabel)
        self.amountLabel.textAlignment = .right
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .white)
        self.lineView.alpha = 0.1
    }
    
    func configure(with item: Transaction) {
        
        Task {
            guard let transaction = try? await item.retrieveDataIfNeeded() else { return }
            if let from = try? await transaction.from?.retrieveDataIfNeeded() {
                self.avatarView.set(avatar: from)
                self.titleLabel.setText(from.fullName)
            }
            
            self.setAmount(with: transaction.amount)
            self.noteLabel.setText(transaction.note)
            self.layoutNow()
        }.add(to: self.taskPool)
    }
    
    private func setAmount(with amount: Double) {
        if amount < 0 {
            self.amountLabel.setText("- \(amount * -1)")
            self.amountLabel.setTextColor(.T1)
        } else {
            self.amountLabel.setText("+ \(amount)")
            self.amountLabel.setTextColor(.D6)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.squaredSize = 32
        self.avatarView.pin(.left)
        self.avatarView.pin(.top, offset: .xtraLong)
        
        self.amountLabel.setSize(withWidth: self.contentView.width)
        self.amountLabel.pin(.right)
        self.amountLabel.match(.top, to: .top, of: self.avatarView)
         
        let maxWidth = self.contentView.width - self.avatarView.right - Theme.ContentOffset.long.value - self.amountLabel.width
        
        self.titleLabel.setSize(withWidth: maxWidth)
        self.titleLabel.match(.top, to: .top, of: self.avatarView)
        self.titleLabel.match(.left, to: .right, of: self.avatarView, offset: .long)
        
        self.noteLabel.setSize(withWidth: maxWidth)
        self.noteLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
        self.noteLabel.match(.left, to: .left, of: self.titleLabel)
        
        self.lineView.height = 1
        self.lineView.expandToSuperviewWidth()
        self.lineView.pin(.bottom)
    }
}
