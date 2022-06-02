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
    
    let darkBlur = DarkBlurView()
        
    override func initializeViews() {
        super.initializeViews()
        
        self.view.insertSubview(self.darkBlur, at: 0)
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.faceCaptureVC.$hasRenderedFaceImage
            .mainSink { [unowned self] hasRendered in
                logDebug(hasRendered)
                if hasRendered {
                    self.currentState = .scanEyesOpen
                }
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.darkBlur.expandToSuperviewSize()
    }
}
