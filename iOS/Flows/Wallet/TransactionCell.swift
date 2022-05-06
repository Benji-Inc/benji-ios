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
    
    func configure(with item: Transaction) {
        self.currentItem = item
        self.setNeedsUpdateConfiguration()
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        // Create new configuration object and update it base on state
        var newConfiguration = TransactionContentConfiguration().updated(for: state)
        
        // Update any configuration parameters related to data item
        newConfiguration.transaction = self.currentItem
        
        // Set content configuration in order to update custom content view
        self.contentConfiguration = newConfiguration
    }
}

class TransactionContentView: BaseView, UIContentView {
    
    private var currentConfiguration: TransactionContentConfiguration!
    
    var configuration: UIContentConfiguration {
        get {
            return self.currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? TransactionContentConfiguration else {
                return
            }
            
            self.apply(configuration: newConfiguration)
        }
    }
    
    @IBOutlet weak var content: UIView!
    
    @IBOutlet weak var avatarView: BorderedPersonView?
    @IBOutlet weak var titleLabel: ThemeLabel?
    @IBOutlet weak var noteLabel: ThemeLabel?
    @IBOutlet weak var amountLabel: ThemeLabel?
    @IBOutlet weak var lineView: BaseView?
    @IBOutlet weak var badgeView: MiniBadgeView?
    
    init(configuration: TransactionContentConfiguration) {
        super.init()
        
        self.loadNib()
        self.apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func loadNib() {
        Bundle.main.loadNibNamed("\(TransactionContentView.self)", owner: self, options: nil)
        
        self.addSubview(self.content)
        self.content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.content.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            self.content.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            self.content.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
            self.content.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
        ])
                
        self.titleLabel?.setFont(.small)
        self.titleLabel?.setTextColor(.whiteWithAlpha)
        self.titleLabel?.alpha = 0.35
        self.titleLabel?.textAlignment = .left
        self.noteLabel?.setFont(.regular)
        self.noteLabel?.textAlignment = .left
        self.noteLabel?.lineBreakMode = .byTruncatingTail
        self.noteLabel?.setTextColor(.white)
        self.amountLabel?.setFont(.regular)
        self.amountLabel?.textAlignment = .right
        
        self.lineView?.set(backgroundColor: .white)
        self.lineView?.alpha = 0.1
    }
    
    private func apply(configuration: TransactionContentConfiguration) {

        guard self.currentConfiguration != configuration else {
            return
        }
        
        self.currentConfiguration = configuration
        
        guard let transaction = configuration.transaction else { return }
        
        self.updateLayout(with: transaction)
    }
    
    private func updateLayout(with item: Transaction) {
        Task {
            guard let transaction = try? await item.retrieveDataIfNeeded() else { return }
            if let from = try? await transaction.nonMeUser?.retrieveDataIfNeeded() {
                self.avatarView?.set(person: from)
                self.titleLabel?.setText(from.fullName)
                self.setNeedsUpdateConstraints()
            }
            
            if let achievement = try? await transaction.achievement?.retrieveDataIfNeeded(),
               let type = try? await achievement.type?.retrieveDataIfNeeded() {
                self.badgeView?.configure(with: type)
                self.badgeView?.isVisible = true
                self.amountLabel?.isVisible = false
            } else {
                self.badgeView?.isVisible = false
                self.amountLabel?.isVisible = true 
            }
            
            self.setAmount(with: transaction.amount)
            self.noteLabel?.setText(transaction.note)
        }.add(to: self.taskPool)
    }
    
    private func setAmount(with amount: Double) {
        if amount < 0 {
            self.amountLabel?.setText("- \(amount * -1)")
            self.amountLabel?.setTextColor(.white)
        } else {
            self.amountLabel?.setText("+ \(amount)")
            self.amountLabel?.setTextColor(.D6)
        }
    }
}

struct TransactionContentConfiguration: UIContentConfiguration, Hashable {
    
    var transaction: Transaction?
    
    func makeContentView() -> UIView & UIContentView {
        return TransactionContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> TransactionContentConfiguration {
        return self
    }
}
