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

    private var displayableTask: Task<Void, Never>?
    var displayable: ImageDisplayable? {
        didSet {
            self.displayableTask?.cancel()

            let displayableRef = self.displayable

            self.displayableTask = Task {
                await self.updateImageView(with: displayableRef)
            }
        }
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
                self.blurView.showBlur(true)
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
        self.blurView.layer.cornerRadius = Theme.innerCornerRadius

        self.animationView.squaredSize = 20
        self.animationView.centerOnXAndY()
    }

    @MainActor
    private func updateImageView(with displayable: ImageDisplayable?) async {
        if let photo = displayable?.image {
            await self.set(image: photo, state: .success)
        } else if let fileObject = displayable?.fileObject {
            await self.downloadAndSetImage(for: fileObject)
        } else if let file = displayable as? PFFileObject {
            await self.downloadAndSet(file: file)
        } else {
            await self.set(image: nil, state: .initial)
        }
    }

    private func downloadAndSetImage(for fileObject: PFFileObject) async {
        await self.downloadAndSet(file: fileObject)
    }

    private func downloadAndSet(file: PFFileObject) async {
        do {
            if !file.isDataAvailable {
                self.state = .loading
            }

            let data = try await file.retrieveDataInBackground { _ in }

            guard !Task.isCancelled else { return }

            let image = await UIImage(data: data)?.byPreparingForDisplay()

            guard !Task.isCancelled else { return }

            await self.set(image: image, state: image.exists ? .success : .error)
        } catch {
            guard !Task.isCancelled else { return }

            await self.set(image: nil, state: .error)
        }
    }

    @MainActor
    private func set(image: UIImage?, state: State) async {
        self.state = state
        self.imageView.image = await image?.byPreparingForDisplay()

        self.setNeedsLayout()
    }
}
