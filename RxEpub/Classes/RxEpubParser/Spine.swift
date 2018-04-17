//
//  FRSpine.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

public class Spine: NSObject {
    var pageProgressionDirection: String?
    public var spineReferences = [Resource]()

    var isRtl: Bool {
        if let pageProgressionDirection = pageProgressionDirection , pageProgressionDirection == "rtl" {
            return true
        }
        return false
    }

    func nextChapter(_ href: String) -> Resource? {
        var found = false;

        for item in spineReferences {
            if(found){
                return item
            }

            if(item.href == href) {
                found = true
            }
        }
        return nil
    }
}
