//
//  ConversationListCoordinator+Attachments.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhotosUI

extension ConversationListCoordinator {
    
    func handle(attachmentOption option: AttachmentOption) {
        
        switch option {
        case .attachements(let array):
            guard let first = array.first else { return }
            let text = self.conversationListVC.messageInputController.swipeInputView.textView.text ?? ""
            Task.onMainActorAsync {
                guard let kind = try? await AttachmentsManager.shared.getMessageKind(for: first, body: text) else { return }
                self.conversationListVC.messageInputController.currentMessageKind = kind
            }
        case .capture:
            self.presentPhotoCapture()
        case .audio:
            break
        case .giphy:
            break
        case .video:
            break
        case .library:
            break
            #warning("Problem when dismissing picker, and not being able to assign first responder")
            //self.presentPhotoLibrary()
        }
    }
    
    func presentPhotoCapture() {
        
    }
    
    func presentPhotoLibrary() {
        self.conversationListVC.present(self.pickerVC, animated: true) {
        }
    }
}

extension ConversationListCoordinator: PHPickerViewControllerDelegate {
    
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        Task.onMainActor {
            self.conversationListVC.dismiss(animated: true) {
                self.conversationListVC.becomeFirstResponder()
            }
        }
    }
}
