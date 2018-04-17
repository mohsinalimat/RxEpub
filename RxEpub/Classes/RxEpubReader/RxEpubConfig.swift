//
//  RxEpubConfig.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/11.
//

import UIKit
import RxCocoa
import RxSwift
class RxEpubConfig: NSObject {
    var scrollDirection:ScrollDirection = .none
    let lastPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    let nextPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    let currentPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    
    static let config = RxEpubConfig()
    static var `default`:RxEpubConfig{
        return config
    }
}
