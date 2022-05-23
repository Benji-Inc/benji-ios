//
//  ModalViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class ModalViewController: ViewController {
    
    private let topGradientView
    = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                   startPoint: .topCenter,
                   endPoint: .bottomCenter)
    
    private let bottomGradientView
      = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                     startPoint: .bottomCenter,
                     endPoint: .topCenter)
    
    var bottomGradientHeight: CGFloat = 94
    var topGradientHeight: CGFloat = Theme.ContentOffset.screenPadding.value
    
    let darkBlurView = DarkBlurView()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = self.shouldShowGrabber()
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.addSubview(self.darkBlurView)
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
    }
    
    // Overrides
    
    func shouldShowGrabber() -> Bool {
        return true
    }
    
    func availableDetents() -> [UISheetPresentationController.Detent] {
        return [.large()]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.darkBlurView.expandToSuperviewSize()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = Theme.ContentOffset.screenPadding.value
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = self.bottomGradientHeight
        self.bottomGradientView.pin(.bottom)
    }
}
