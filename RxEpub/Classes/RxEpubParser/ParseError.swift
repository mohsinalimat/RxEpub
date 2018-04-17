//
//  ParseError.swift
//  RxEpub
//
//  Created by zhoubin on 2018/3/27.
//

import UIKit

enum ParseError:Error {
    case fileNotExist(url:String)
    case parse
    case rootfiles
    case opf
    case download
    case zip
}

