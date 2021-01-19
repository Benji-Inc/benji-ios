//
//  AttachementInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import Combine

class AttachmentViewController: CollectionViewController<AttachementCell, AttachmentCollectionViewManager> {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))

    init() {
        super.init(with: AttachmentCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        guard let window = UIWindow.topWindow() else { return }
        self.view.size = CGSize(width: window.width, height: window.height * 0.4)

        let color = Color.background1.color.withAlphaComponent(0.9)
        self.view.backgroundColor = color
        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)

        self.collectionViewManager.didSelectPhotoOption = {
            NotificationCenter.default.post(name: .didTapPhotoCamera, object: nil)
        }

        self.collectionViewManager.didSelectLibraryOption = {
            NotificationCenter.default.post(name: .didTapPhotoLibrary, object: nil)
        }

        if let attachmentCollectionView = self.collectionView as? AttachmentCollectionView {
            attachmentCollectionView.didTapAuthorize = { [unowned self] in
                self.requestAuthorization()
                    .mainSink(receivedResult: { (result) in
                        switch result {
                        case .success():
                            self.fetchAssets()
                        case .error(_):
                            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }).store(in: &self.cancellables)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.checkPhotoAuthorizationStatus()
    }

    private func checkPhotoAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch (status) {
        case .authorized, .limited:
            self.fetchAssets()
        default:
            break
        }
    }

    private func requestAuthorization() -> Future<Void, Error> {
        return Future { promise in
            PHPhotoLibrary.requestAuthorization({ (status) in
                switch status {
                case .authorized, .limited:
                    promise(.success(()))
                default:
                    promise(.failure(ClientError.message(detail: "Failed to authorize")))
                }
            })
        }
    }

    private func fetchAssets() {
        let photosOptions = PHFetchOptions()
        photosOptions.fetchLimit = 20
        photosOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                              PHAssetMediaType.image.rawValue)
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: photosOptions)

        var attachments: [Attachement] = []

        for index in 0...result.count - 1 {
            let asset = result.object(at: index)
            let attachement = Attachement(with: asset)
            attachments.append(attachement)
        }

        self.collectionViewManager.set(newItems: attachments)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.collectionView.expandToSuperviewWidth()
        self.collectionView.pin(.top)
        self.collectionView.height = self.view.height - self.view.safeAreaInsets.bottom
    }
}

extension Notification.Name {
    static let didTapPhotoCamera = Notification.Name("didTapPhotoCamera")
    static let didTapPhotoLibrary = Notification.Name("didTapPhotoLibrary")
}
