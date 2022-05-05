//
//  WalletHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StoreKit

class WalletHeaderView: BaseView {
    
    private let topLeftDetailView = WalletHeaderDetailView(shouldPinLeft: true, showDetail: true)
    private let bottomLeftDetailView = WalletHeaderDetailView(shouldPinLeft: true, showDetail: false)
    private let topRightDetailView = JibsDetailView()
    private let bottomRightDetailView = BallanceDetailView()
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
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.topLeftDetailView)
        self.addSubview(self.bottomLeftDetailView)
        self.addSubview(self.topRightDetailView)
        self.addSubview(self.bottomRightDetailView)
        self.addSubview(self.imageView)
        
        self.topLeftDetailView.didSelect { [unowned self] in
            self.didTapDetail?()
        }
    }
    
    func configure(with items: [Transaction]) {
        self.topLeftDetailView.configure(with: "Jibs", subtitle: "Reward Credits")
        Task {
            guard let user = try? await User.current()?.retrieveDataIfNeeded(),
            let createdAt = user.createdAt else { return }
            
            let dateString = Date.monthYear.string(from: createdAt)
            
            if let memberPosition = User.current()?.quePosition {
                self.bottomLeftDetailView.configure(with: "#\(memberPosition)",
                                                    subtitle: "Member since \(dateString)")
            } else {
                self.bottomLeftDetailView.configure(with: "Jibber", subtitle: "Member since \(dateString)")
            }
            
            self.topRightDetailView.subtitleLabel.setText("Earned for activity")
            self.bottomRightDetailView.subtitleLabel.setText("Total Balance")
            self.startCalculatingInterest(for: items)
            
            self.layoutNow()
        }
    }

    private var interestTask: Task<Void, Never>?

    func startCalculatingInterest(for transactions: [Transaction]) {
        self.interestTask?.cancel()
        
        let calculator = TransactionsCalculator()
        
        self.interestTask = Task { [weak self] in
            guard let `self` = self,
                  let jibsEarned = try? await calculator.calculateJibsEarned(for: transactions),
                  !Task.isCancelled else { return }
            
            let projectedInterest = calculator.calculateInterestEarned()
            let totalEarned = jibsEarned + projectedInterest
            
            self.topRightDetailView.configure(with: totalEarned)
            
            let totalCurrencyEarned = calculator.calculateCreditBalanceForJibs(for: totalEarned)
            self.bottomRightDetailView.configure(with: totalCurrencyEarned)
            self.layoutNow()
            
            await Task.snooze(seconds: 1.0)
            
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
}
