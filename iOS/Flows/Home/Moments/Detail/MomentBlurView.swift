//
//  MomentBlurView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class MomentBlurView: BaseView {
    
    let blurEffect = UIBlurEffect(style: .systemThinMaterial)
    lazy var blurredEffectView = UIVisualEffectView(effect: nil)
    lazy var vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: self.blurEffect))
    
    let imageView = SymbolImageView(symbol: .eyeSlash)
    let label = ThemeLabel(font: .regular)
    let button = ThemeButton()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.blurredEffectView)
        
        self.blurredEffectView.contentView.addSubview(self.vibrancyEffectView)
        
        self.vibrancyEffectView.contentView.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.white.color
        
        self.vibrancyEffectView.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        
        self.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Record Moment"))
    }
    
    func configure(for moment: Moment) {
        Task {
            guard let moment = try? await moment.retrieveDataIfNeeded() else { return }
            
            if moment.isAvailable {
                self.button.isVisible = false
                self.label.setText("Loading...")
                self.layoutNow()
            } else if let person = try? await moment.author?.retrieveDataIfNeeded() {
                self.label.setText("To view this Moment from \(person.givenName),\nfirst share one of yours.")
                self.button.isVisible = true
                self.layoutNow()
            }            
        }
    }
    
    func animateBlur(shouldShow: Bool) {
        Task {
            await UIView.awaitAnimation(with: .fast) {
                self.blurredEffectView.effect = shouldShow ? self.blurEffect : nil
                self.alpha = shouldShow ? 1.0 : 0
                self.layoutNow()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.blurredEffectView.expandToSuperviewSize()
        self.vibrancyEffectView.expandToSuperviewSize()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.label.centerOnXAndY()
        
        self.imageView.squaredSize = 50
        self.imageView.match(.bottom, to: .top, of: self.label, offset: .negative(.xtraLong))
        self.imageView.centerOnX()
        
        self.button.setSize(with: self.width)
        self.button.centerOnX()
        self.button.pinToSafeAreaBottom()
    }
}
