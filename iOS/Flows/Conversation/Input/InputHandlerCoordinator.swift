//
//  InputHandlerCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PhotosUI
import Photos
import Localization
import Lightbox

protocol SwipeableInputControllerHandler where Self: ViewController {
    var messageCellDelegate: MesssageCellDelegate? { get set }
    var swipeableVC: SwipeableInputAccessoryViewController { get }
    func updateUI(for state: ConversationUIState, forceLayout: Bool)
}

typealias InputHandlerViewContoller = SwipeableInputControllerHandler & ViewController

class InputHandlerCoordinator<Result>: PresentableCoordinator<Result>,
                                       ActiveConversationable,
                                       PHPickerViewControllerDelegate,
                                       UIImagePickerControllerDelegate,
                                       UINavigationControllerDelegate {
    
    lazy var captureVC: UIImagePickerController = {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        return vc
    }()
    
    let inputHandlerViewController: InputHandlerViewContoller
    
    init(with viewContoller: InputHandlerViewContoller,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.inputHandlerViewController = viewContoller
        super.init(router: router, deepLink: deepLink)
    }
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.inputHandlerViewController
    }
    
    override func start() {
        super.start()
        
        self.inputHandlerViewController.swipeableVC.swipeInputView.addView.didSelect { [unowned self] in
            self.presentAttachments()
        }
    }
    
    func presentAttachments() {
        let coordinator = AttachmentsCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.present(coordinator) { [unowned self] result in
            self.handle(attachmentOption: result)
        }
    }
    
    func present<ChildResult>(_ coordinator: PresentableCoordinator<ChildResult>,
                              finishedHandler: ((ChildResult) -> Void)? = nil,
                              cancelHandler: (() -> Void)? = nil) {
        self.removeChild()
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
            self.inputHandlerViewController.becomeFirstResponder()
        }
        
        self.addChildAndStart(coordinator) { [unowned self, unowned coordinator] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.inputHandlerViewController.becomeFirstResponder()
                finishedHandler?(result)
            }
        }
        
        self.inputHandlerViewController.resignFirstResponder()
        self.inputHandlerViewController.updateUI(for: .read, forceLayout: true)
        self.router.present(coordinator, source: self.inputHandlerViewController, cancelHandler: cancelHandler)
    }
    
    func handle(attachmentOption option: AttachmentOption) {
        switch option {
        case .attachments(let array):
            guard let first = array.first else { return }
            let text = self.inputHandlerViewController.swipeableVC.swipeInputView.textView.text ?? ""
            Task.onMainActorAsync {
                guard let kind = try? await AttachmentsManager.shared.getMessageKind(for: first, body: text) else { return }
                self.inputHandlerViewController.swipeableVC.currentMessageKind = kind
                self.inputHandlerViewController.swipeableVC.inputState = .collapsed
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
            self.presentPhotoLibrary()
        }
    }
    
    func presentPhotoCapture() {
        let cameraMediaType = AVMediaType.video
        let status = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch status {
        case .denied:
            break
        case .authorized:
            self.toPresentable().present(self.captureVC, animated: true, completion: nil)
        case .restricted:
            break
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    self.toPresentable().present(self.captureVC, animated: true, completion: nil)
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
        @unknown default:
            break
        }
    }
    
    func presentPhotoLibrary() {
        let filter = PHPickerFilter.any(of: [.images])
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = filter
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        
        self.toPresentable().present(vc, animated: true)
    }
    
    // https://developer.apple.com/documentation/photokit/selecting_photos_and_videos_in_ios
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        Task.onMainActorAsync {
            
            self.inputHandlerViewController.dismiss(animated: true)
            
            let text = self.inputHandlerViewController.swipeableVC.swipeInputView.textView.text ?? ""
            
            guard let indentifier = results.first?.assetIdentifier,
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [indentifier], options: nil).firstObject,
                  let kind = try? await AttachmentsManager.shared.getMessageKind(for: Attachment(asset: asset), body: text) else { return }
            
            self.inputHandlerViewController.swipeableVC.currentMessageKind = kind
            self.inputHandlerViewController.swipeableVC.inputState = .collapsed
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [unowned self] in
            self.toPresentable().becomeFirstResponder()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) { [unowned self] in
            self.toPresentable().becomeFirstResponder()
            
            Task.onMainActorAsync {
                let text = self.inputHandlerViewController.swipeableVC.swipeInputView.textView.text ?? ""
                guard let kind = try? await AttachmentsManager.shared.getMessageKind(for: info, body: text) else { return }
                self.inputHandlerViewController.swipeableVC.currentMessageKind = kind
                self.inputHandlerViewController.swipeableVC.inputState = .collapsed
            }
        }
    }
}

// MARK: - Image View Flow

extension ConversationListCoordinator {

    func presentImageFlow(for imageURLs: [URL], startingURL: URL?) {
        let imageCoordinator = ImageViewCoordinator(imageURLs: imageURLs,
                                                    startURL: startingURL,
                                                    router: self.router,
                                                    deepLink: self.deepLink)

        self.present(imageCoordinator)
    }
}
