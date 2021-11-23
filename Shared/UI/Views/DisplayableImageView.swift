//
//  DisplayableImageView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import SDWebImageLinkPlugin
import UIKit
import Combine
import Lottie

class DisplayableImageView: View {

    private(set) var imageView = UIImageView()
    var cancellables = Set<AnyCancellable>()

    let blurView = BlurView()

    enum State {
        case initial
        case loading
        case error
        case success
    }

    @Published var state: State = .initial

    let animationView = AnimationView()

    var displayable: ImageDisplayable? {
        didSet {
            guard let displayable = self.displayable else {
                self.showResult(for: nil)
                return
            }

            self.updateImageView(with: displayable)
            self.setNeedsLayout()
        }
    }

    var didDisplayImage: ((UIImage) -> Void)? = nil

    deinit {
        self.reset()
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill

        self.addSubview(self.blurView)
        self.blurView.contentView.addSubview(self.animationView)

        self.$state.mainSink { state in
            switch state {
            case .initial:
                self.animationView.reset()
                self.animationView.stop()
                self.blurView.showBlur(false)
            case .loading:
                UIView.animate(withDuration: 0.2) {
                    self.blurView.showBlur(true)
                }
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
                self.animationView.loopMode = .loop
                self.animationView.load(animation: .loading)
                self.animationView.play()
            case .error:
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
                self.animationView.load(animation: .error)
                self.animationView.loopMode = .loop
                self.animationView.play()
                UIView.animate(withDuration: 0.2) {
                    self.blurView.showBlur(true)
                }
            case .success:
                if self.animationView.isAnimationPlaying {
                    self.animationView.stop()
                }
                self.animationView.reset()

                UIView.animate(withDuration: 0.2) {
                    self.blurView.showBlur(false)
                }
            }
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()

        self.animationView.squaredSize = 20
        self.animationView.centerOnXAndY()
    }

    func updateImageView(with displayable: ImageDisplayable) {
        if let photo = displayable.image {
            self.showResult(for: photo)
        } else if let url = displayable.url {
            Task {
                await self.downloadAndSetImage(url: url)
            }.add(to: self.taskPool)
        } else if let objectID = displayable.userObjectID {
            Task {
                await self.findUser(with: objectID)
            }.add(to: self.taskPool)
        } else if let file = displayable as? PFFileObject {
            Task {
                await self.downloadAndSet(file: file)
            }.add(to: self.taskPool)
        }
    }

    private func downloadAndSetImage(for user: User) {

        Task {
            if user.focusStatus == .focused, let file = user.focusImage {
                await self.downloadAndSet(file: file)
            } else if let file = user.smallImage {
                await self.downloadAndSet(file: file)
            }
        }.add(to: self.taskPool)
    }

    private func findUser(with objectID: String) async {

        var foundUser: User? = nil

        if let user = UserStore.shared.users.first(where: { user in
            return user.objectId == objectID
        }) {
            foundUser = user
        } else if let user = try? await User.getObject(with: objectID) {
            foundUser = user
        }

        if let user = foundUser {
            self.downloadAndSetImage(for: user)
        }
    }

    @MainActor
    private func downloadAndSetImage(url: URL) async {
        self.state = .loading
        let downloadedImage: UIImage?
        = try? await self.imageView.setImageWithURL(url, progressHandler: { received, expected, url in
            if self.animationView.microAnimation == .pie {
                let progress: Float
                if received > 0 {
                    progress = (Float(expected) - Float(received)) / Float(expected) * 100
                } else {
                    progress = 0
                }
                self.animationView.currentProgress = AnimationProgressTime(progress)
            }
        })

        guard !Task.isCancelled else { return }

        self.showResult(for: downloadedImage)
    }

    @MainActor
    private func downloadAndSet(file: PFFileObject) async {

        do {
            if !file.isDataAvailable {
                self.state = .loading
            }
            let data = try await file.retrieveDataInBackground { progress in
                if self.animationView.microAnimation == .pie {
                    let time = AnimationProgressTime(progress)
                    self.animationView.currentProgress = time
                }
            }

            guard !Task.isCancelled else { return }

            guard let image = UIImage(data: data) else {
                self.showResult(for: nil)
                return
            }

            self.showResult(for: image)
        } catch {
            guard !Task.isCancelled else { return }
            self.showResult(for: nil)
        }
    }

    func reset() {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }

        Task {
            await self.taskPool.cancelAndRemoveAll()
        }

        self.displayable = nil
        self.animationView.stop()
        self.blurView.showBlur(true)
    }

    func showResult(for image: UIImage?) {
        self.state = image.isNil ? .error : .success
        self.imageView.image = image
    }
}

fileprivate extension UIImageView {

    func setImageWithURL(_ url: URL,
                         progressHandler: @escaping SDImageLoaderProgressBlock) async throws -> UIImage? {

        let image: UIImage? = try await withCheckedThrowingContinuation { continuation in
            self.sd_setImage(with: url, placeholderImage: nil, progress: progressHandler)
            { (image, error, cacheType, url) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }

        return image
    }
}
