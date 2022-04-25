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

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.addSubview(self.label)

        self.set(backgroundColor: .badgeHighlightTop)

        let configuration = UIImage.SymbolConfiguration(pointSize: 12.5)
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
                self.imageView.alpha = 0.0
                self.setNeedsLayout()
            })
            
            self.imageView.image = type.image
            self.label.setText(type.description)
            
            guard !Task.isCancelled else { return }
        
            await UIView.awaitAnimation(with: .standard, animations: {
                self.alpha = 1.0
                self.label.alpha = 1.0
                self.imageView.alpha = 1.0
                self.setNeedsLayout()
            })
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: 200)
        self.height = 24
        self.width = 24 + Theme.ContentOffset.short.value.doubled + self.label.width + Theme.ContentOffset.short.value
        self.imageView.squaredSize = self.height
        self.imageView.pin(.left, offset: .short)
        self.label.match(.left, to: .right, of: self.imageView)
        
        self.imageView.centerOnY()
        self.label.centerY = self.imageView.centerY

        self.layer.cornerRadius = self.halfHeight
    }
}
