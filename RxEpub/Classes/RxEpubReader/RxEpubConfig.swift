//
//  RxEpubConfig.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/11.
//

import UIKit
import RxCocoa
import RxSwift
public class RxEpubConfig: NSObject {
    public let backgroundColor = Variable("#cce8cf")
    public let textColor = Variable("#818181")
    public let fontSize:Variable<CGFloat> = Variable(14)
    public let backgroundImage:Variable<String?> = Variable(nil)
}
