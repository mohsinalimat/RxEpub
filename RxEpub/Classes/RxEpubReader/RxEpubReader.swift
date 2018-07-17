//
//  RxEpubReader.swift
//  RxEpub
//
//  Created by zhoubin on 2018/3/26.
//

import UIKit
import RxSwift
public class RxEpubReader: NSObject {
    private static var reader:RxEpubReader? = nil
    
    var scrollDirection:ScrollDirection = .none
    let lastPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    let nextPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    let currentPage:Variable<Page> = Variable(Page(chapter:0,page:0))
    
    public var config:RxEpubConfig! = RxEpubConfig()
    public var clickCallBack:(()->())? = nil
    public static var shared:RxEpubReader{
        if reader == nil{
            reader = RxEpubReader()
        }
        return reader!
    }
    public static func remove(){
        reader = nil
    }
}
