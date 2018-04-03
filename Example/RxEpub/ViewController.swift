//
//  ViewController.swift
//  RxEpub
//
//  Created by izhoubin on 03/26/2018.
//  Copyright (c) 2018 izhoubin. All rights reserved.
//

import UIKit
import RxEpub
import RxSwift
import WebKit
class ViewController: UIViewController {
    let bag = DisposeBag()
    let webView = WKWebView(frame: UIScreen.main.bounds)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
//        let url = URL(string:"http://d18.ixdzs.com/64/64960/64960.epub")
        let url = URL(string:"http://mebookj.magook.com/epub1/14887/14887-330151/330151_08e3035f.epub")
//        let url = URL(string:"http://d18.ixdzs.com/64/64960/64960.epub")
//        let url = Bundle.main.url(forResource: "恰到好处的幸福", withExtension: "epub")
//        let url =  URL(string:"http://mebookj.magook.com/epub1/14887/14887-330151/330151_08e3035f")
//        let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("恰到好处的幸福")

        RxEpubParser(url: url!).parse().subscribe(onNext: {[weak self] (book) in
            if let url = book.resources.resources.first?.value.url{
                let req = URLRequest(url: url)
                self?.webView.load(req)
            }
        }, onError: { (err) in
            print(err)
        }).disposed(by: bag)
    }
    
}

