//
//  NoticeContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeContentView: BaseView {
    
    var didSelectRemove: CompletionOptional = nil
    var didSelectPrimaryOption: CompletionOptional = nil
    var didSelectSecondaryOption: CompletionOptional = nil
    
    private let removeButton = ThemeButton()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B6)
        self.layer.cornerRadius = Theme.cornerRadius
        
        var config = ImageSymbol.xMarkCircleFill.defaultConfig
        config = config?.applying(UIImage.SymbolConfiguration.init(pointSize: 26))
        
        self.removeButton.set(style: .image(symbol: .xMarkCircleFill,
                                            palletteColors: [.whiteWithAlpha],
                                            pointSize: 26,
                                            backgroundColor: .clear))

        self.removeButton.didSelect { [unowned self] in
            self.didSelectRemove?()
        }
        
        self.addSubview(self.removeButton)
    }
    
    func configure(for notice: SystemNotice) async {}
    
    func showError() {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.bringSubviewToFront(self.removeButton)
        
        self.removeButton.squaredSize = 44
        self.removeButton.pin(.top)
        self.removeButton.pin(.right)
    }
}
