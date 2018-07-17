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
class ViewController: UIViewController {
//    let bag = DisposeBag()
//    let webView = RxEpubWebView(frame:UIScreen.main.bounds)//RxEpubWebView(frame: CGRect(x: 30, y: 40, width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height - 80))//
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.setToolbarHidden(false, animated: true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let url = Bundle.main.url(forResource: "330151", withExtension: "epub")
//        let url =  URL(string:"http://localhost/330151")
//        let url = URL(string: "http://localhost/330151.epub")
//        let url = URL(string:"http://mebookj.magook.com/epub1/14887/14887-330151/330151_08e3035f")!
        let url = URL(string: "http://d18.ixdzs.com/195/195195/195195.epub")!
        //        let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("330151")
        let vc = RxEpubPageController(url:url)
        navigationController?.pushViewController(vc, animated: true)
        RxEpubReader.shared.config.backgroundColor.value = "#C7EDCC"
        RxEpubReader.shared.config.textColor.value = "#525252"
//        RxEpubReader.shared.config.backgroundImage.value = "羊皮纸"
        RxEpubReader.shared.clickCallBack = {[weak self] in
            print("点击")
            let isHidden = self?.navigationController?.isNavigationBarHidden ?? false
            self?.navigationController?.setNavigationBarHidden(!isHidden, animated: true)
        }
    }
}

