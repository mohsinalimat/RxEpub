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
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var url:URL!
    public convenience init(url:URL) {
        self.init(nibName: nil, bundle: nil)
        self.url = url
    }
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setUpShemes()
        setUpCollectionView()
        setUpIndicator()
        setUpRx()
    }
    func setUpIndicator(){
        view.addSubview(indicator)
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        indicator.center = view.center
    }
    func setUpRx(){
        let startOffset = collectionView.rx.willBeginDragging.map{[weak self] in
            return self?.collectionView.contentOffset ?? CGPoint.zero
        }
        Observable.combineLatest(startOffset, collectionView.rx.contentOffset) { (p1, p2) -> ScrollDirection in
            if p1.x > p2.x{
                return .right
            }else if p1.x < p2.x{
                return .left
            }else{
                return .none
            }
        }.subscribe(onNext: { (direction) in
            if direction != .none{
                RxEpubReader.shared.scrollDirection = direction
            }
        }).disposed(by: bag)
        
        RxEpubReader.shared.config.backgroundColor.asObservable().subscribe(onNext:{[weak self] in
            self?.view.backgroundColor = UIColor(hexString: $0)
        }).disposed(by: bag)

        RxEpubParser(url: url).parse().subscribe(onNext: {[weak self] (book) in
            self?.book = book
            self?.collectionView.reloadData()
            self?.indicator.stopAnimating()
            }, onError: { (err) in
                print(err)
        }).disposed(by: bag)

        Observable.combineLatest(RxEpubReader.shared.config.backgroundImage.asObservable(), RxEpubReader.shared.config.textColor.asObservable(),RxEpubReader.shared.config.fontSize.asObservable()).subscribe(onNext: {[weak self] (_) in
            self?.collectionView.reloadData()
        }).disposed(by: bag)

        //为了保持统一，这里也设置同样的背景图
        RxEpubReader.shared.config.backgroundImage.asObservable().subscribe(onNext: {[weak self] (imageName) in
            if let imageName = imageName{
                let bundle = Bundle(for: RxEpubReader.self)
                let path = bundle.path(forResource: imageName, ofType: "jpg") ?? ""
                self?.view.layer.contents = UIImage(contentsOfFile: path)?.cgImage
            }
        }).disposed(by: bag)
    }
    
    func setUpShemes(){
        URLProtocol.registerClass(RxEpubURLProtocol.self)
        URLProtocol.wk_register(scheme: "http")
        URLProtocol.wk_register(scheme: "https")
        URLProtocol.wk_register(scheme: "file")
        URLProtocol.wk_register(scheme: "App")
    }
    deinit {
        URLProtocol.wk_unregister(scheme: "http")
        URLProtocol.wk_unregister(scheme: "https")
        URLProtocol.wk_unregister(scheme: "file")
        URLProtocol.wk_unregister(scheme: "App")
        URLProtocol.unregisterClass(RxEpubURLProtocol.self)
        RxEpubReader.remove()
    }
    
    func setUpCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        if #available(iOS 11, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
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
        
        let tapgs = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapgs.delegate = self
        view.addGestureRecognizer(tapgs)
    }
    @objc func tap(){
        RxEpubReader.shared.clickCallBack?()
    }
}
extension RxEpubPageController:UIGestureRecognizerDelegate{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
            cell.webView.tapCallBack = {[weak self] in
               self?.tap()
            }
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIScreen.main.bounds.size
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
extension UIColor{
    public convenience init?(hexString: String, transparency: CGFloat = 1) {
        var string = ""
        if hexString.lowercased().hasPrefix("0x") {
            string =  hexString.replacingOccurrences(of: "0x", with: "")
        } else if hexString.hasPrefix("#") {
            string = hexString.replacingOccurrences(of: "#", with: "")
        } else {
            string = hexString
        }
        
        if string.count == 3 { // convert hex to 6 digit format if in short format
            var str = ""
            string.forEach { str.append(String(repeating: String($0), count: 2)) }
            string = str
        }
        
        guard let hexValue = Int(string, radix: 16) else { return nil }
        
        var trans = transparency
        if trans < 0 { trans = 0 }
        if trans > 1 { trans = 1 }
        
        let red = (hexValue >> 16) & 0xff
        let green = (hexValue >> 8) & 0xff
        let blue = hexValue & 0xff
        guard red >= 0 && red <= 255 else { return nil }
        guard green >= 0 && green <= 255 else { return nil }
        guard blue >= 0 && blue <= 255 else { return nil }
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: trans)
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
