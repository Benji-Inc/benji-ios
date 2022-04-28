//
//  ModalPhotoViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A profile photo view controller with a popopver presentation style.
class ModalPhotoViewController: ProfilePhotoCaptureViewController {
    
    private let label = ThemeLabel(font: .small, textColor: .B0)
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        self.view.insertSubview(self.label, belowSubview: self.errorView)
        
        self.label.setText("Smile then tap")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.currentState = .scanEyesOpen
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        self.label.setSize(withWidth: self.view.width)
        let offset = ((self.view.width * 0.9) * 0.5) + Theme.ContentOffset.long.value
        self.label.center.y = (self.view.halfHeight * 0.95) - offset
        self.label.centerOnX()
    }
}
