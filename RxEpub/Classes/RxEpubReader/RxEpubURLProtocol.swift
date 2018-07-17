//
//  RxEpubURLProtocol.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/10.
//

import UIKit
private let KHybridNSURLProtocolHKey = "KHybridNSURLProtocol"
class RxEpubURLProtocol: URLProtocol,URLSessionDelegate,URLSessionDataDelegate,URLSessionTaskDelegate {
    var rxTask: URLSessionTask? = nil
    override class func canInit(with request: URLRequest) -> Bool{
        if request.url?.scheme?.lowercased() == "app",
            request.url?.host == "RxEpub"{
            if URLProtocol.property(forKey: KHybridNSURLProtocolHKey, in: request) != nil{
                return false
            }
            return true
        }
        return false
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest{
        //request截取重定向
        var req = request
        let url = Bundle(for: RxEpubReader.self).bundleURL.appendingPathComponent(req.url?.lastPathComponent ?? "")
        req.url = url
        return req
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool{
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        URLProtocol.setProperty(true, forKey: KHybridNSURLProtocolHKey, in: request as! NSMutableURLRequest)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        rxTask = session.dataTask(with: request)
        rxTask?.resume()
    }
    
    override func stopLoading() {
        rxTask?.cancel()
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.allowed)
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        client?.urlProtocolDidFinishLoading(self)
    }
}
