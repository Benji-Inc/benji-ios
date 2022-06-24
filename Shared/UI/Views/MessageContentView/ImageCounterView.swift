//
//  ImageCounterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class ImageCounterView: BaseView {
    
    enum ViewState {
        case empty
        case add
        case count(Int)
    }
    
    enum SelectionState {
        case normal
        case selected
    }
    
    @Published var viewState: ViewState = .empty
    @Published var selectionState: SelectionState = .normal
    
    static let height: CGFloat = 26
    
    lazy var imageView = SymbolImageView(symbol: self.symbol)
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.small.font,
                                      textColor: ThemeColor.white.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    private let symbol: ImageSymbol
    
    init(with symbol: ImageSymbol) {
        self.symbol = symbol
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.height = ImageCounterView.height
        
        self.layer.borderColor = ThemeColor.white.color.cgColor
        self.imageView.tintColor = ThemeColor.white.color
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        self.imageView.setPoint(size: 10)
        
        self.addSubview(self.counter)
        
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderWidth = 0.5
        
        self.$viewState.mainSink { [unowned self] state in
            self.handleView(state: state)
        }.store(in: &self.cancellables)
        
        self.$selectionState.mainSink { [unowned self] state in
            self.handleSelection(state: state)
        }.store(in: &self.cancellables)
        
        self.didSelect { [unowned self] in
            if self.selectionState == .normal {
                self.selectionState = .selected
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let offset = Theme.ContentOffset.standard
        
        self.imageView.squaredSize = 18
        self.imageView.centerOnY()
        
        self.counter.sizeToFit()
        self.counter.centerOnY()
        
        self.width
        = offset.value.doubled + self.imageView.width
        + self.counter.width + offset.value
        
        self.imageView.pin(.left, offset: offset)
        self.counter.match(.left, to: .right, of: self.imageView, offset: offset)
    }
    
    /// The currently running task that is animating the view state.
    private var viewStateTask: Task<Void, Never>?
    
    func handleView(state: ViewState) {
        
        self.viewStateTask?.cancel()
        
        self.viewStateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
//            await UIView.awaitAnimation(with: .slow, animations: {
//                switch state {
//                case .empty:
//                    self.counter.alpha = 0
//                case .add:
//                    self.counter.alpha = 0
//                case .count(let count):
//                    self.counter.alpha = count > 0 ? 1.0 : 0
//                }
//
//                self.layoutNow()
//            })
            
            if case ViewState.count(let count) = state {
                self.counter.setValue(Float(count), animated: true)
                self.layoutNow()
            }
        }
    }
    
    func handleSelection(state: SelectionState) {
        Task {
            await UIView.awaitAnimation(with: .fast, animations: {
                switch state {
                case .normal:
                    self.alpha = 0.35
                case .selected:
                    self.alpha = 1.0
                }
            })
        }
    }
}
