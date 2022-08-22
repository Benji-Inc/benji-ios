//
//  Moment.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

 enum MomentKey: String {
     case author
     case expression
     case file
     case preview
     case caption
 }

 final class Moment: PFObject, PFSubclassing {

     static func parseClassName() -> String {
         return String(describing: self)
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
