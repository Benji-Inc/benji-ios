//
//  PostConfirmationViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import Combine

class PostReviewViewController: ViewController {

    private(set) var animationView = AnimationView(name: "arrow")
    private(set) var backButton = Button()
    
    let detailsView = PostReviewDetailsView()

    let swipeLabel = Label(font: .largeThin)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.detailsView)

        self.animationView.transform = CGAffineTransform(rotationAngle: halfPi * -1)
        self.view.addSubview(self.backButton)
        self.backButton.set(style: .animation(view: self.animationView))
        self.backButton.didSelect { [unowned self] in
            // go back
        }
        self.view.addSubview(self.backButton)
        self.view.addSubview(self.swipeLabel)
        self.swipeLabel.setText("Swipe up to post")
        self.swipeLabel.textAlignment = .center
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.detailsView.expandToSuperviewWidth()
        self.detailsView.height = self.view.height * 0.6
        self.detailsView.pin(.top)

        self.backButton.size = CGSize(width: 40, height: 40)
        self.backButton.left = Theme.contentOffset - 10
        self.backButton.top = Theme.contentOffset

        self.swipeLabel.setSize(withWidth: self.view.width)
        self.swipeLabel.centerOnX()
        self.swipeLabel.pinToSafeArea(.bottom, padding: Theme.contentOffset.doubled)
    }

//    func createPost(progressHandler: @escaping (Int) -> Void) -> Future<Void, Error> {
//        return Future { promise in
//            if let image = self.imageView.image, let data = image.data, let preview = image.previewData {
//                FeedManager.shared.createPost(with: data, previewData: preview, progressHandler: progressHandler)
//                    .mainSink { post in
//                        self.reset()
//                        promise(.success(()))
//                    }.store(in: &self.cancellables)
//            } else {
//                promise(.failure(ClientError.apiError(detail: "No image for post")))
//            }
//        }
//    }
}
