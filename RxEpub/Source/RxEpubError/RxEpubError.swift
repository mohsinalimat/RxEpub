//
//  RxEpubError.swift
//  RxEpub
//
//  Created by zhoubin on 2018/3/27.
//

import UIKit

enum RxEpubError:Error {
    case fileNotExist(url:String)
    case parse
    case rootfiles
    case opf
}

