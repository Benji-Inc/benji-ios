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
    private let topRightDetailView = DetailView(shouldPinLeft: false, showDetail: true)
    private let bottomRightDetailView = DetailView(shouldPinLeft: false)
    private let imageView = UIImageView(image: UIImage(named: "jiblogo"))
    
    var didTapDetail: CompletionOptional = nil
    
    private let totalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 6
        return formatter
    }()
    
    private let balanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "usd"
        formatter.roundingMode = .down
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    var interestTask: Task<Void, Never>?
    
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
        
        self.topRightDetailView.didSelect { [unowned self] in
            self.didTapDetail?()
        }
    }
    
    func configure(with items: [WalletCollectionViewDataSource.ItemType]) {
        self.topLeftDetailView.configure(with: "Jibs", subtitle: "Reward Credits")
        Task {
            guard let user = try? await User.current()?.retrieveDataIfNeeded(),
            let createdAt = user.createdAt else { return }
            
            let dateString = Date.monthYear.string(from: createdAt)
            
            if let memberPosition = User.current()?.quePosition {
                self.bottomLeftDetailView.configure(with: "#\(memberPosition)", subtitle: "Member since \(dateString)")
            } else {
                self.bottomLeftDetailView.configure(with: "Jibber", subtitle: "Member since \(dateString)")
            }
            
            let transactions: [Transaction] = items.compactMap { type in
                switch type {
                case .transaction(let transaction):
                    return transaction
                }
            }
            self.startCalculatingInterest(for: transactions)
        }
    }
    
    func startCalculatingInterest(for transactions: [Transaction]) {
        self.interestTask?.cancel()
        
        let calculator = TransactionsCalculator()
        
        self.interestTask = Task { [unowned self] in
            
            guard let jibsEarned = try? await calculator.calculateJibsEarned(for: transactions), !Task.isCancelled else { return }
            
            let projectedInterest = calculator.calculateInterestEarned(for: transactions)
            let totalEarned = jibsEarned + projectedInterest
            
            if let stringTotal = self.totalFormatter.string(from: NSNumber(value: totalEarned)) {
                self.topRightDetailView.configure(with: stringTotal, subtitle: "Earned for activity")
            }
            
            let totalCurrencyEarned = calculator.calculateCreditBalanceForJibs(for: totalEarned)
    
            let balance = self.balanceFormatter.string(from: NSNumber(value: totalCurrencyEarned)) ?? "$0.00"
            self.bottomRightDetailView.configure(with: balance, subtitle: "Credit Balance")
            self.layoutNow()
            await Task.snooze(seconds: 0.5)
            
            guard !Task.isCancelled else { return }
            self.startCalculatingInterest(for: transactions)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.topLeftDetailView.pin(.left)
        self.topLeftDetailView.pin(.top, offset: .screenPadding)
        
        self.bottomLeftDetailView.pin(.bottom, offset: .screenPadding)
        self.bottomLeftDetailView.pin(.left)
        
        self.topRightDetailView.pin(.right)
        self.topRightDetailView.pin(.top, offset: .screenPadding)
        
        self.bottomRightDetailView.pin(.right)
        self.bottomRightDetailView.pin(.bottom, offset: .screenPadding)
        
        self.imageView.squaredSize = 160
        self.imageView.centerOnX()
        self.imageView.centerY = self.centerY - Theme.ContentOffset.screenPadding.value.half
        self.imageView.centerY += 10
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.interestTask?.cancel()
    }
}

private class DetailView: BaseView {
    let titleLabel = ThemeLabel(font: .medium)
    let subtitleLabel = ThemeLabel(font: .small, textColor: .D1)
    private let detailDisclosure = UIImageView(image: UIImage(systemName: "info.circle"))

    private let shouldPinLeft: Bool
    private let showDetail: Bool
    
    init(shouldPinLeft: Bool, showDetail: Bool = false) {
        self.shouldPinLeft = shouldPinLeft
        self.showDetail = showDetail
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.detailDisclosure)
        self.tintColor = ThemeColor.T1.color
        self.detailDisclosure.isHidden = !self.showDetail
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
        
        self.height = self.titleLabel.height + Theme.ContentOffset.short.value + self.subtitleLabel.height
        if self.showDetail {
            self.width = self.titleLabel.width + Theme.ContentOffset.short.value + 18
        } else {
            self.width = self.titleLabel.width > self.subtitleLabel.width ? self.titleLabel.width : self.subtitleLabel.width
        }
        
        if self.shouldPinLeft {
            self.titleLabel.pin(.left)
            self.subtitleLabel.pin(.left)
        } else {
            self.titleLabel.pin(.right)
            self.subtitleLabel.pin(.right)
        }
        
        self.titleLabel.pin(.top)
        self.subtitleLabel.pin(.bottom)
        
        self.detailDisclosure.squaredSize = 18
        self.detailDisclosure.centerY = self.titleLabel.centerY
        self.detailDisclosure.match(.right, to: .left, of: self.titleLabel, offset: .negative(.short))
    }
}
