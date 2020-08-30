//
//  AttachementInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos

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

        self.checkPhotoAuthorizationStatus { [weak self] (authorized) in
            guard let `self` = self else { return }
            self.fetchAssets()
        }

        self.view.set(backgroundColor: .background1)
        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
    }

    private func checkPhotoAuthorizationStatus(completion: @escaping (_ authorized: Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch (status) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                completion(status == .authorized)
            })
        @unknown default:
            fatalError()
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
