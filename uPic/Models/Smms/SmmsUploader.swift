//
//  SmmsUploader.swift
//  uPic
//
//  Created by Svend Jin on 2019/6/10.
//  Copyright © 2019 Svend Jin. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire

class SmmsUploader: BaseUploader {

    static let shared = SmmsUploader()

    static let fileExtensions: [String] = ["jpeg", "jpg", "png", "gif", "bmp"]
    
    // limit 5M
    static let limitSize: UInt64 = 5 * 1024 * 1024
    
    let v1_url = "https://sm.ms/api/upload"
    let v2_url = "https://sm.ms/api/v2/upload"

    func _upload(_ fileUrl: URL?, fileData: Data?, host: Host) {
        guard let data = host.data, let config = data as? SmmsHostConfig else {
            super.faild(errorMsg: "There is a problem with the map bed configuration, please check!".localized)
            return
        }
        
        super.start()
        
        let url = config.version == SmmsVersion.v2.rawValue ? v2_url : v1_url
        

        guard let configuration = BaseUploaderUtil.getSaveConfiguration(fileUrl, fileData, nil) else {
            super.faild(errorMsg: "Invalid file")
            return
        }
        
        let retData = configuration["retData"] as? Data
        let fileName = configuration["fileName"] as! String
        let mimeType = configuration["mimeType"] as! String
        
        var headers: HTTPHeaders?
        if config.version == SmmsVersion.v2.rawValue {
            headers = HTTPHeaders()
            headers?.add(HTTPHeader.authorization(config.token!))
            headers?.add(HTTPHeader.contentType("multipart/form-data"))
        }
        
        func multipartFormDataGen(multipartFormData: MultipartFormData) {
            if retData != nil {
                multipartFormData.append(retData!, withName: "smfile", fileName: fileName, mimeType: mimeType)
            } else if fileUrl != nil {
                multipartFormData.append(fileUrl!, withName: "smfile", fileName: fileName, mimeType: mimeType)
            }
        }

        AF.upload(multipartFormData: multipartFormDataGen, to: url, method: HTTPMethod.post, headers: headers).validate().uploadProgress { progress in
            super.progress(percent: progress.fractionCompleted)
        }.responseJSON(completionHandler: { response -> Void in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let success = json["success"].intValue
                if 0 == success {
                    let msg = json["message"].stringValue
                    super.faild(errorMsg: msg)
                } else {
                    let data = json["data"]
                    let url = data["url"].stringValue
                    super.completed(url: url, retData, fileUrl, nil)
                }
            case .failure(let error):
                super.faild(errorMsg: error.localizedDescription)
            }
        })

    }
    
    func upload(_ fileUrl: URL, host: Host) {
        self._upload(fileUrl, fileData: nil, host: host)
    }
    
    func upload(_ fileData: Data, host: Host) {
        self._upload(nil, fileData: fileData, host: host)
    }
}
