//
//  TocReference.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

open class TocReference: NSObject {
    var children: [TocReference]!

    public var title: String!
    public var resource: Resource?
    public var fragmentID: String?
    
    convenience init(title: String, resource: Resource?, fragmentID: String = "") {
        self.init(title: title, resource: resource, fragmentID: fragmentID, children: [TocReference]())
    }

    init(title: String, resource: Resource?, fragmentID: String, children: [TocReference]) {
        self.resource = resource
        self.title = title
        self.fragmentID = fragmentID
        self.children = children
    }
}

// MARK: Equatable

func ==(lhs: TocReference, rhs: TocReference) -> Bool {
    return lhs.title == rhs.title && lhs.fragmentID == rhs.fragmentID
}
