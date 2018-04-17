//
//  RxEpubPageController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/4.
//

import UIKit
import RxSwift
import RxCocoa
enum ScrollType: Int {
    case page
    // `chapter` is only for the collection view if vertical with horizontal content is used
    case chapter
}

enum ScrollDirection: Int {
    case none
    case right
    case left
}
struct Page {
    var chapter:Int
    var page:Int
}
open class RxEpubPageController: UIViewController {
    var book:Book? = nil
    let bag = DisposeBag()
    var collectionView:UICollectionView!
    let scrollDirection:Variable<ScrollDirection> = Variable(.none)
    override open func viewDidLoad() {
        super.viewDidLoad()
        URLProtocol.registerClass(RxEpubURLProtocol.self)
        URLProtocol.wk_register(scheme: "http")
        URLProtocol.wk_register(scheme: "https")
        URLProtocol.wk_register(scheme: "file")
        URLProtocol.wk_register(scheme: "App")
        setUpCollectionView()
        loadData()
        view.backgroundColor = UIColor.red
        // Do any additional setup after loading the view.
    }
    deinit {
        URLProtocol.wk_unregister(scheme: "http")
        URLProtocol.wk_unregister(scheme: "https")
        URLProtocol.wk_unregister(scheme: "file")
        URLProtocol.wk_unregister(scheme: "App")
        URLProtocol.unregisterClass(RxEpubURLProtocol.self)
    }
    
    func loadData(){
//                let url = Bundle.main.url(forResource: "330151", withExtension: "epub")
                let url =  URL(string:"http://localhost/330151")
//        let url = URL(string: "http://localhost/330151.epub")
//        let url = URL(string:"http://mebookj.magook.com/epub1/14887/14887-330151/330151_08e3035f")
//        let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("330151")
        
        RxEpubParser(url: url!).parse().subscribe(onNext: {[weak self] (book) in
            self?.book = book
            self?.collectionView.reloadData()
            }, onError: { (err) in
                print(err)
        }).disposed(by: bag)
    }
    
    func setUpCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        view.addConstraints([left,right,top,bottom])
        
        collectionView.register(RxEpubPageCell.self, forCellWithReuseIdentifier: "RxEpubPageCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Observable.combineLatest(collectionView.rx.willBeginDragging.map{self.collectionView.contentOffset}, collectionView.rx.contentOffset) { (p1, p2) -> ScrollDirection in
                if p1.x > p2.x{
                    return .right
                }else if p1.x < p2.x{
                    return .left
                }else{
                    return .none
                }
            }.subscribe(onNext: { (direction) in
                if direction != .none{
                    RxEpubConfig.default.scrollDirection = direction
                }
            }).disposed(by: bag)
    }
}
extension RxEpubPageController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return book?.spine.spineReferences.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RxEpubPageCell", for: indexPath) as! RxEpubPageCell
        if let url = book?.spine.spineReferences[indexPath.row].url{
            let req = URLRequest(url: url)
            cell.webView.load(req)
            cell.webView.scrollView.delegate = self
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIScreen.main.bounds.size
    }
}
//extension RxEpubPageController:UIScrollViewDelegate{
//    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        pointNow = scrollView.contentOffset
//        if scrollView is UICollectionView {
//            print("跨章节翻页开始")
//        }else{
//            print("章节内翻页开始")
//        }
//    }
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView is UICollectionView {
//            print("跨章节翻页")
//            print(scrollView.contentOffset.x/UIScreen.main.bounds.width)
//        }else{
//            print("章节内翻页")
//        }
//    }
//    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//
//    }
//    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//
//    }
//    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        if scrollView is UICollectionView {
//            print("跨章节翻页结束")
//            print(scrollView.contentOffset.x/UIScreen.main.bounds.width)
//        }else{
//            print("章节内翻页结束")
//        }
//    }
//}
