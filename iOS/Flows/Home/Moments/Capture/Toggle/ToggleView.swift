//
//  ToggleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ToggleView: BaseView {
    
    enum ToggleType {
        case location
        case weather
        case emotions
        
        var symbol: ImageSymbol {
            switch self {
            case .location:
                return .mappingPin
            case .weather:
                return .cloudRain
            case .emotions:
                return .heart
            }
        }
        
        var text: String {
            switch self {
            case .location:
                return "Location"
            case .weather:
                return "Weather"
            case .emotions:
                return "Emotions"
            }
        }
    }
    
    let label = ThemeLabel(font: .small)
    let button = ThemeButton()
    @Published var isON: Bool = false
   
    private let type: ToggleType
    
    init(type: ToggleType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.setTextColor(.white)
        self.addSubview(self.button)
        
        self.button.didSelect { [unowned self] in
            // do stuff
            self.isON.toggle()
            self.updateButtonState()
        }
        
        self.label.setText(type.text)
        self.button.set(style: .image(symbol: type.symbol, palletteColors: [.white], pointSize: 30, backgroundColor: .whiteWithAlpha))
    }
    
    func updateButtonState() {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.width = 70
        self.height = 100
        
        self.button.squaredSize = self.width
        self.button.pin(.top)
        self.button.centerOnX()
        self.button.makeRound()
        
        self.label.setSize(withWidth: self.width.doubled)
        self.label.match(.top, to: .bottom, of: self.button, offset: .standard)
        self.label.centerOnX()
    }
}
