//
//  DeliveryTypeBadgeView.swift
//  Jibber
//
//  Created by Martin Young on 3/31/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MessageDeliveryTypeBadgeView: BaseView {

    @Published var deliveryType: MessageDeliveryType?
    private var cancellables = Set<AnyCancellable>()

    private let imageView = UIImageView()
    private let label = ThemeLabel(font: .small)
    private let deliveryTypeLabel = ThemeLabel(font: .xtraSmall)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.addSubview(self.label)
        self.addSubview(self.deliveryTypeLabel)

        self.set(backgroundColor: .badgeHighlightTop)

        let configuration = UIImage.SymbolConfiguration(pointSize: 16.5)
        self.imageView.preferredSymbolConfiguration = configuration
        self.imageView.tintColor = ThemeColor.white.color
        self.imageView.contentMode = .center

        self.$deliveryType
            .removeDuplicates()
            .mainSink { [unowned self] deliveryType in
                self.update(for: deliveryType)
            }.store(in: &self.cancellables)
    }
    
    /// The currently running task.
    private var animateTask: Task<Void, Never>?
        
    private func update(for type: MessageDeliveryType?) {
        self.animateTask?.cancel()

        self.animateTask = Task { [weak self] in
            guard let `self` = self, let type = type else {
                await UIView.awaitAnimation(with: .fast, animations: {
                    self?.alpha = 0.0
                })
                return
            }
            
            await UIView.awaitAnimation(with: .standard, animations: {
                self.alpha = 1.0
                self.label.alpha = 0.0
                self.deliveryTypeLabel.alpha = 0.0
                self.imageView.alpha = 0.0
                self.setNeedsLayout()
            })
            
            self.imageView.image = type.image
            self.deliveryTypeLabel.setText(type.displayName)
            self.label.setText(type.description)
            
            guard !Task.isCancelled else { return }
        
            await UIView.awaitAnimation(with: .standard, animations: {
                self.alpha = 1.0
                self.label.alpha = 1.0
                self.deliveryTypeLabel.alpha = 1.0
                self.imageView.alpha = 1.0
                self.setNeedsLayout()
            })
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.deliveryTypeLabel.setSize(withWidth: 200)
        self.label.setSize(withWidth: 200)
        self.height = 30
        self.width = 30 + Theme.ContentOffset.short.value.doubled + self.label.width + Theme.ContentOffset.standard.value
        self.imageView.squaredSize = self.height
        self.imageView.pin(.left)
        self.label.match(.left, to: .right, of: self.imageView)
        self.deliveryTypeLabel.match(.left, to: .left, of: self.label)
        
        self.imageView.centerOnY()
        self.deliveryTypeLabel.pin(.top, offset: .custom(2))
        self.label.pin(.bottom, offset: .custom(4))

        self.layer.cornerRadius = self.halfHeight
    }
}
