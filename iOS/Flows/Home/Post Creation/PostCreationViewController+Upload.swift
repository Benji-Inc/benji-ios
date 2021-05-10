//
//  PostCreateViewController+Upload.swift
//  Ours
//
//  Created by Benji Dodgson on 4/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

extension PostCreationViewController {

    func preload(data: Data, preview: Data, progressHandler: @escaping (Int) -> Void) -> Future<Void, Error> {

        return Future { promise in

            self.file = PFFileObject(name: UUID().uuidString, data: data)
            self.file?.saveInBackground({ success, error in
                if let e = error {
                    promise(.failure(e))
                } else {
                    self.previewFile = PFFileObject(name: UUID().uuidString, data: preview)
                    self.previewFile?.saveInBackground(block: { completed, error in
                        if let e = error {
                            promise(.failure(e))
                        } else {
                            promise(.success(()))
                        }
                    })
                }
            }, progressBlock: { progress in
                progressHandler(Int(progress))
            })
        }
    }

    func createPost() -> Future<Post, Error> {
        let post = Post()
        post.author = User.current()!
        post.body = self.captionTextView.text
        post.priority = 2
        post.triggerDate = self.datePicker.date
        post.expirationDate = Date.add(component: .day, amount: 2, toDate: self.datePicker.date)
        post.type = .media
        var attributes: [String: Any] = [:]
        if let attachment = self.attachment {
            attributes["mediaType"] = attachment.asset.mediaType
        }
        post.attributes = [:]
        post.duration = 5
        post.preview = self.previewFile
        post.file = self.file
        return post.saveToServer()
    }
}
