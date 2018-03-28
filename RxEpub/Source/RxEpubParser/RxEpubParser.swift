//
//  RxEpubParser.swift
//  RxEpub
//
//  Created by zhoubin on 2018/3/26.
//

import UIKit
import RxSwift
import AEXML
import SSZipArchive
public class RxEpubParser: NSObject {
    var rootUrl:URL!
    let book = Book()
    var resourcesBaseUrl:URL!
    public init(url:URL) {
        self.rootUrl = url
        super.init()
    }
    
    public func parse()->Observable<Book>{
        var isDir:ObjCBool = false
        let needsUnzip = rootUrl.isFileURL && (!FileManager.default.fileExists(atPath: rootUrl.path, isDirectory: &isDir) || !isDir.boolValue)
        if needsUnzip {
            print("需要解压")
            let unzipFile = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!.appendingPathComponent("Epubs").appendingPathComponent(rootUrl.deletingPathExtension().lastPathComponent)
            
            if SSZipArchive.unzipFile(atPath: rootUrl.path, toDestination: unzipFile.path, delegate: nil){
                print("解压成功:",unzipFile.path)
                rootUrl = unzipFile
            }
        }else{
            print("不需要解压")
        }
        
        let containerPath = "META-INF/container.xml"
        let containerUrl = rootUrl.appendingPathComponent(containerPath)
        return read(url: containerUrl).flatMap {
                self.parseContainer(container: $0)
            }.flatMap { (opfResource) -> Observable<AEXMLDocument> in
                let opfUrl = self.rootUrl.appendingPathComponent(opfResource.href)
                return self.read(url:opfUrl)
            }.flatMap{opf -> Observable<URL> in
                self.parseOpf(opf: opf)
            }.flatMap{tocUrl -> Observable<AEXMLDocument> in
                return self.read(url:tocUrl)
            }.flatMap{toc -> Observable<Book> in
                self.parseToc(toc: toc)
                return Observable.just(self.book)
            }.observeOn(MainScheduler.asyncInstance)
    }
    
    func read(url:URL) ->Observable<AEXMLDocument>{
        return Observable.create { (observer) -> Disposable in
            if url.isFileURL{//本地文件
                if !FileManager.default.fileExists(atPath: url.path){//文件不存在
                    observer.onError(RxEpubError.fileNotExist(url:url.absoluteString.removingPercentEncoding ?? ""))
                }else if let data = try? Data(contentsOf: url, options: .alwaysMapped), let xmlDoc = try? AEXMLDocument(xml: data) {//正常解析
                    observer.onNext(xmlDoc)
                    observer.onCompleted()
                }else{//解析失败
                    observer.onError(RxEpubError.parse)
                    assertionFailure(url.absoluteString)
                }
                return Disposables.create()
            }else{//远程文件
                let task = URLSession.shared.dataTask(with: url) { (data, _, err) in
                    if let data = data,let xmlDoc = try? AEXMLDocument(xml: data){
                        observer.onNext(xmlDoc)
                        observer.onCompleted()
                    }else{
                        observer.onError(RxEpubError.parse)
                        assertionFailure(url.absoluteString)
                    }
                }
                task.resume()
                return Disposables.create {
                    task.cancel()
                }
            }
        }
    }
    
    func parseContainer(container: AEXMLDocument) ->Observable<Resource>{
        let opfResource = Resource()
        opfResource.href = container.root["rootfiles"]["rootfile"].attributes["full-path"]
        guard let fullPath = container.root["rootfiles"]["rootfile"].attributes["full-path"] else {
            return Observable.error(RxEpubError.rootfiles)
        }
        opfResource.mediaType = MediaType.by(fileName: fullPath)
        book.opfResource = opfResource
        let oebpsHref = (book.opfResource.href as NSString).deletingLastPathComponent
        resourcesBaseUrl = rootUrl.appendingPathComponent(oebpsHref)
        return Observable.just(opfResource)
    }
    
    func parseOpf(opf:AEXMLDocument)->Observable<URL>{
        var identifier: String?
        if let package = opf.children.first {
            identifier = package.attributes["unique-identifier"]
            
            if let version = package.attributes["version"] {
                book.version = Double(version)
            }
        }
        
        // Read Spine
        let spine = opf.root["spine"]
        book.spine = readSpine(spine.children)
        let tocItemIdref = spine.attributes["toc"]
        // Parse and save each "manifest item"
        var tocHref:String? = nil
        opf.root["manifest"]["item"].all?.forEach {
            let resource = Resource()
            resource.id = $0.attributes["id"]
            
            resource.properties = $0.attributes["properties"]
            resource.href = $0.attributes["href"]
            //TODO: - 类型待定,取决于用的时候用String还是URL
            resource.fullHref = resourcesBaseUrl.appendingPathComponent(resource.href).absoluteString.removingPercentEncoding
            resource.url = resourcesBaseUrl.appendingPathComponent(resource.href)
            resource.mediaType = MediaType.by(name: $0.attributes["media-type"] ?? "", fileName: resource.href)
            resource.mediaOverlay = $0.attributes["media-overlay"]
            
            // if a .smil file is listed in resources, go parse that file now and save it on book model
            if (resource.mediaType != nil && resource.mediaType == .smil) {
                readSmilFile(resource)
            }
            //标记目录Item
            if resource.id == tocItemIdref{
                tocHref = resource.href
                book.tocResource = resource
            }
            book.resources.add(resource)
        }
        
        book.smils.baseUrl = resourcesBaseUrl
        
        // Read metadata
        book.metadata = readMetadata(opf.root["metadata"].children)
        
        // Read the book unique identifier
        if let identifier = identifier, let uniqueIdentifier = book.metadata.find(identifierById: identifier) {
            book.uniqueIdentifier = uniqueIdentifier.value
        }
        
        // Read the cover image
        let coverImageId = book.metadata.find(byName: "cover")?.content
        if let coverImageId = coverImageId, let coverResource = book.resources.findById(coverImageId) {
            book.coverImage = coverResource
        } else if let coverResource = book.resources.findByProperty("cover-image") {
            book.coverImage = coverResource
        }
        
        assert(book.tocResource != nil, "ERROR: 无法解析出目录路径")
        
        if let href = tocHref {
            return Observable.just(resourcesBaseUrl.appendingPathComponent(href))
        }else{
            //此处不能报错，否则整体报错
            return Observable.empty()
        }
    }
    
    /// Read and parse the Table of Contents.
    ///
    /// - Returns: A list of toc references
    private func parseToc(toc:AEXMLDocument) -> Observable<[TocReference]> {
        var tableOfContent = [TocReference]()
        var tocItems: [AEXMLElement]?
        guard let tocResource = book.tocResource else {
            return Observable.just(tableOfContent)
        }
        do {
            if tocResource.mediaType == MediaType.ncx {
                if let itemsList = toc.root["navMap"]["navPoint"].all {
                    tocItems = itemsList
                }
            } else {
                if let nav = toc.root["body"]["nav"].first, let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                } else if let nav = findNavTag(toc.root["body"]), let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                }
            }
        } catch {
            assertionFailure("目录解析出错")
        }
        
        guard let items = tocItems else {
            return Observable.just(tableOfContent)
        }
        
        for item in items {
            guard let ref = readTOCReference(item) else { continue }
            tableOfContent.append(ref)
        }
        book.tableOfContents = tableOfContent
        return Observable.just(tableOfContent)
    }
    //递归取出子目录
    fileprivate func readTOCReference(_ navpointElement: AEXMLElement) -> TocReference? {
        var label = ""
        
        if book.tocResource?.mediaType == MediaType.ncx {
            if let labelText = navpointElement["navLabel"]["text"].value {
                label = labelText
            }
            
            guard let reference = navpointElement["content"].attributes["src"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]
            
            let resource = book.resources.findByHref(href)
            let toc = TocReference(title: label, resource: resource, fragmentID: fragmentID)
            
            // Recursively find child
            if let navPoints = navpointElement["navPoint"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        } else {
            if let labelText = navpointElement["a"].value {
                label = labelText
            }
            
            guard let reference = navpointElement["a"].attributes["href"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]
            
            let resource = book.resources.findByHref(href)
            let toc = TocReference(title: label, resource: resource, fragmentID: fragmentID)
            
            // Recursively find child
            if let navPoints = navpointElement["ol"]["li"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        }
    }
    @discardableResult func findNavTag(_ element: AEXMLElement) -> AEXMLElement? {
        for element in element.children {
            if let nav = element["nav"].first {
                return nav
            } else {
                findNavTag(element)
            }
        }
        return nil
    }
    
    /// Reads and parses a .smil file.
    ///
    /// - Parameter resource: A `Resource` to read the smill
    private func readSmilFile(_ resource: Resource) {
        do {
            let smilData = try Data(contentsOf: URL(fileURLWithPath: resource.fullHref), options: .alwaysMapped)
            var smilFile = FRSmilFile(resource: resource)
            let xmlDoc = try AEXMLDocument(xml: smilData)
            
            let children = xmlDoc.root["body"].children
            
            if children.count > 0 {
                smilFile.data.append(contentsOf: readSmilFileElements(children))
            }
            
            book.smils.add(smilFile)
        } catch {
            print("Cannot read .smil file: "+resource.href)
        }
    }
    
    
    private func readSmilFileElements(_ children: [AEXMLElement]) -> [SmilElement] {
        var data = [SmilElement]()
        
        // convert each smil element to a FRSmil object
        children.forEach{
            let smil = SmilElement(name: $0.name, attributes: $0.attributes)
            
            // if this element has children, convert them to objects too
            if $0.children.count > 0 {
                smil.children.append(contentsOf: readSmilFileElements($0.children))
            }
            
            data.append(smil)
        }
        
        return data
    }
    
    fileprivate func readSpine(_ tags: [AEXMLElement]) -> Spine {
        let spine = Spine()
        
        for tag in tags {
            guard let idref = tag.attributes["idref"] else { continue }
            var linear = true
            
            if tag.attributes["linear"] != nil {
                linear = tag.attributes["linear"] == "yes" ? true : false
            }
            
            if book.resources.containsById(idref) {
                guard let resource = book.resources.findById(idref) else { continue }
                spine.spineReferences.append(resource)
            }
        }
        return spine
    }
    
    /// Read and parse <metadata>.
    ///
    /// - Parameter tags: XHTML tags
    /// - Returns: Metadata object
    fileprivate func readMetadata(_ tags: [AEXMLElement]) -> Metadata {
        let metadata = Metadata()
        
        for tag in tags {
            if tag.name == "dc:title" {
                metadata.titles.append(tag.value ?? "")
            }
            
            if tag.name == "dc:identifier" {
                let identifier = Identifier(id: tag.attributes["id"], scheme: tag.attributes["opf:scheme"], value: tag.value)
                metadata.identifiers.append(identifier)
            }
            
            if tag.name == "dc:language" {
                let language = tag.value ?? metadata.language
                metadata.language = language != "en" ? language : metadata.language
            }
            
            if tag.name == "dc:creator" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }
            
            if tag.name == "dc:contributor" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }
            
            if tag.name == "dc:publisher" {
                metadata.publishers.append(tag.value ?? "")
            }
            
            if tag.name == "dc:description" {
                metadata.descriptions.append(tag.value ?? "")
            }
            
            if tag.name == "dc:subject" {
                metadata.subjects.append(tag.value ?? "")
            }
            
            if tag.name == "dc:rights" {
                metadata.rights.append(tag.value ?? "")
            }
            
            if tag.name == "dc:date" {
                metadata.dates.append(EventDate(date: tag.value ?? "", event: tag.attributes["opf:event"] ?? ""))
            }
            
            if tag.name == "meta" {
                if tag.attributes["name"] != nil {
                    metadata.metaAttributes.append(Meta(name: tag.attributes["name"], content: tag.attributes["content"]))
                }
                
                if tag.attributes["property"] != nil && tag.attributes["id"] != nil {
                    metadata.metaAttributes.append(Meta(id: tag.attributes["id"], property: tag.attributes["property"], value: tag.value))
                }
                
                if tag.attributes["property"] != nil {
                    metadata.metaAttributes.append(Meta(property: tag.attributes["property"], value: tag.value, refines: tag.attributes["refines"]))
                }
            }
        }
        return metadata
    }
}
