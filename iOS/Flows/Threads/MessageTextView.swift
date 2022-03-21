//
//  MessageTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/1/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization
 
class MessageTextView: TextView {

    override func initializeViews() {
        super.initializeViews()
        
        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true

        self.textContainerInset.left = 0
        self.textContainerInset.right = 0
        self.textContainerInset.top = 0
        self.textContainerInset.bottom = 0
    }

    func setText(with message: Messageable) {
        switch message.kind {
        case .text(_):
            self.setText(message.kind.text)
        case .attributedText(_):
            break
        case .photo(photo: let photo, body: let body):
            guard let url = photo.url else { return }
            self.loadImage(with: url, with: body)
        case .video(video: let video, body: let body):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .link(_):
            break
        }
        
    }
    
    private func loadImage(with url: URL, with body: String) {
        
        // Create Data Task
           let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
               if let data = data {
                   // Create Image and Update Image View
                   guard let image = UIImage(data: data) else { return }
                   let attachment = NSTextAttachment()
                   attachment.image = image
                   let imageString = NSAttributedString(attachment: attachment)
                   
                   DispatchQueue.main.async {
                       self?.text = body
                       self?.textStorage.insert(imageString, at: body.count)
                   }
                   
                   
                   
                   //textView.textStorage.insert(imageString, at: indexWhereYouWantTheImage)
               }
           }

           // Start Data Task
           dataTask.resume()
    }

    // Allows us to interact with links if they exist or pass the touch to the next receiver if they do not
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // Find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // Check if character is a link and handle normally
            if self.textStorage.attribute(NSAttributedString.Key.link,
                                          at: characterIndex,
                                          effectiveRange: nil) != nil {
                return self
            }
        }

        // Return nil to pass touch to next receiver
        return nil
    }
}
