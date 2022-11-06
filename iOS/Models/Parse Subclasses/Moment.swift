//
//  Moment.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import LinkPresentation

 enum MomentKey: String {
     case author
     case expression
     case file
     case preview
     case caption
     case location
 }

 final class Moment: PFObject, PFSubclassing {

     static func parseClassName() -> String {
         return String(describing: self)
     }
     
     var isAvailable: Bool {
         return MomentsStore.shared.hasRecordedToday || self.isFromCurrentUser
     }
     
     var isFromCurrentUser: Bool {
         return self.author?.objectId == User.current()?.objectId
     }
     
     var commentsId: String {
         guard let objectId = self.objectId else { return "" }
         return "moment:" + objectId
     }

     var author: User? {
         get { self.getObject(for: .author) }
         set { self.setObject(for: .author, with: newValue) }
     }

     var expression: Expression? {
         get { self.getObject(for: .expression) }
         set { self.setObject(for: .expression, with: newValue) }
     }

     var file: PFFileObject? {
         get { self.getObject(for: .file) }
         set { self.setObject(for: .file, with: newValue) }
     }
     
     var preview: PFFileObject? {
         get { self.getObject(for: .preview) }
         set { self.setObject(for: .preview, with: newValue) }
     }
     
     var caption: String? {
         get { self.getObject(for: .caption) }
         set { self.setObject(for: .caption, with: newValue) }
     }
     
     var location: PFGeoPoint? {
         get { self.getObject(for: .location) }
         set { self.setObject(for: .location, with: newValue) }
     }
 }

 extension Moment: Objectable {
     typealias KeyType = MomentKey

     func getObject<Type>(for key: MomentKey) -> Type? {
         return self.object(forKey: key.rawValue) as? Type
     }

     func setObject<Type>(for key: MomentKey, with newValue: Type) {
         self.setObject(newValue, forKey: key.rawValue)
     }

     func getRelationalObject<PFRelation>(for key: MomentKey) -> PFRelation? {
         return self.relation(forKey: key.rawValue) as? PFRelation
     }
 }

 extension Moment: ImageDisplayable {

     var image: UIImage? {
         return nil
     }

     var imageFileObject: PFFileObject? {
         return self.file
     }
 }

private var urlKey: UInt8 = 0
extension Moment: UIActivityItemSource {
    
    private(set) var previewURL: URL? {
        get {
            return self.getAssociatedObject(&urlKey)
        }
        set {
            self.setAssociatedObject(key: &urlKey, value: newValue)
        }
    }
    
    func prepareMetadata() async {
        _ = try? await self.retrieveDataIfNeeded()
        self.previewURL = try? await self.preview?.retrieveCachedPathURL()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let link =  Config.domain + "/moment?momentId=\(self.objectId!)"
        return "Check out my moment 🤳\n\(link)"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return ""
    }
    
    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Share Moment"
        return metadata
    }
}
