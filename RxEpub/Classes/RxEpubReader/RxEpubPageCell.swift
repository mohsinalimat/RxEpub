//
//  RxEpubPageCell.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/4.
//

import UIKit

class RxEpubPageCell: UICollectionViewCell {
    let webView = RxEpubWebView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        contentView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: webView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        contentView.addConstraints([left,right,top,bottom])
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
