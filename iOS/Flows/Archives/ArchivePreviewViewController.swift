//
//  ArchivePreviewViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 5/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivePreviewViewController: ViewController {

    let post: Post
    let size: CGSize

    private let imageView = DisplayableImageView()
    private let videoView = VideoView()

    init(with post: Post, size: CGSize) {
        self.post = post
        self.size = size
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        guard let file = self.post.file else { return }

        let new = CGSize(width: self.size.width * 3, height: self.size.height * 3)
        self.preferredContentSize = new

        if self.post.pixelSize.width > self.post.pixelSize.height {
            self.imageView.contentMode = .scaleAspectFit
            self.videoView.contentMode = .scaleAspectFit
        } else {
            self.imageView.contentMode = .scaleAspectFill
            self.videoView.contentMode = .scaleAspectFill
        }

        self.videoView.didSelect { [unowned self] in
            self.videoView.replay()
        }

        if let type = post.mediaType {
            switch type {
            case .unknown:
                break
            case .image:
                break
            case .video:
                self.view.addSubview(self.videoView)

                file.retrieveDataInBackground(progressHandler: { progress in

                }).mainSink(receiveValue: { data in
                    self.imageView.removeFromSuperview()
                    self.view.insertSubview(self.videoView, at: 0)
                    self.view.layoutNow()

                    self.videoView.data = data

                    self.videoView.replay()

                }).store(in: &self.cancellables)

            case .audio:
                break
            @unknown default:
                break
            }
        } else {
            self.view.addSubview(self.imageView)
            self.imageView.displayable = file
        }

        self.view.set(backgroundColor: .background2)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.videoView.isPlaying {
            self.videoView.teardown()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.videoView.expandToSuperviewSize()
    }
}
