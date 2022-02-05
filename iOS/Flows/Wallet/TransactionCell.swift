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
    let titleLabel = ThemeLabel(font: .regular, textColor: .D1)
    let noteLabel = ThemeLabel(font: .small)
    let amountLabel = ThemeLabel(font: .regularBold)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .left
        self.contentView.addSubview(self.noteLabel)
        self.noteLabel.textAlignment = .left
        self.contentView.addSubview(self.amountLabel)
        self.amountLabel.textAlignment = .right
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
            self.amountLabel.setTextColor(.red)
        } else {
            self.amountLabel.setText("+ \(amount)")
            self.amountLabel.setTextColor(.D6)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.squaredSize = 40
        self.avatarView.pin(.left)
        self.avatarView.pin(.top)
        
        self.titleLabel.setSize(withWidth: self.contentView.width)
        self.titleLabel.match(.top, to: .top, of: self.avatarView)
        self.titleLabel.match(.left, to: .right, of: self.avatarView, offset: .standard)
        
        self.noteLabel.setSize(withWidth: self.contentView.width)
        self.noteLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
        self.noteLabel.match(.left, to: .left, of: self.titleLabel)
        
        self.amountLabel.setSize(withWidth: self.contentView.width)
        self.amountLabel.pin(.right)
        self.amountLabel.match(.top, to: .top, of: self.avatarView)
    }
}
