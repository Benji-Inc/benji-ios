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
        
    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentState = .scanEyesOpen
    }
}
