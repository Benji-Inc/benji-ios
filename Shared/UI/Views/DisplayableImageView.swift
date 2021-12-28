//
//  DisplayableImageView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import UIKit
import Combine
import Lottie

class DisplayableImageView: BaseView {

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
            guard let displayable = self.displayable else { return }

            Task {
                await self.updateImageView(with: displayable)
            }.add(to: self.taskPool)
        }
    }

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

        self.$state.mainSink { [weak self] state in
            guard let `self` = self else { return }

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

    func updateImageView(with displayable: ImageDisplayable) async {
        if let photo = displayable.image {
            await self.showResult(for: photo)
        } else if let objectID = displayable.userObjectId {
            let foundUser = await UserStore.shared.findUser(with: objectID)
            if let user = foundUser {
                self.downloadAndSetImage(for: user)
            }
        } else if let file = displayable as? PFFileObject {
            await self.downloadAndSet(file: file)
        }
    }

    private func downloadAndSetImage(for user: User) {
        Task {
            if let file = user.smallImage {
               await self.downloadAndSet(file: file)
           }
        }.add(to: self.taskPool)
    }

    @MainActor
    private func downloadAndSet(file: PFFileObject) async {
        do {
            if !file.isDataAvailable {
                self.state = .loading
            }

            let data = try await file.retrieveDataInBackground { _ in }

            guard !Task.isCancelled else { return }

            let image = await UIImage(data: data)?.byPreparingForDisplay()

            guard !Task.isCancelled else { return }

            await self.showResult(for: image)
        } catch {
            guard !Task.isCancelled else { return }
            await self.showResult(for: nil)
        }
    }

    func reset() {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }

        //TODO: Figure out why this crashes when presenting thread
//        Task {
//            await self.taskPool.cancelAndRemoveAll()
//        }

        self.displayable = nil
        self.animationView.stop()
        self.blurView.showBlur(true)
    }

    @MainActor
    func showResult(for image: UIImage?) async {
        self.state = image.isNil ? .error : .success
        self.imageView.image = await image?.byPreparingForDisplay()
        self.setNeedsLayout()
    }
}
