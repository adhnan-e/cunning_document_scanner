//
//  ScannerOptions.swift
//  cunning_document_scanner
//
//  Created by Maurits van Beusekom on 15/10/2024.
//

import Foundation

enum CunningScannerImageFormat: String {
    case jpg
    case png
}

struct CunningScannerOptions {
    let imageFormat: CunningScannerImageFormat
    let jpgCompressionQuality: Double
    let noOfPages: Int?

    init() {
        self.imageFormat = .png
        self.jpgCompressionQuality = 1.0
        self.noOfPages = nil
    }

    init(imageFormat: CunningScannerImageFormat, jpgCompressionQuality: Double, noOfPages: Int?) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = jpgCompressionQuality
        self.noOfPages = noOfPages
    }

    static func fromArguments(args: Any?) -> CunningScannerOptions {
        if args == nil {
            return CunningScannerOptions()
        }
        
        let arguments = args as? Dictionary<String, Any>
    
        if arguments == nil || arguments!.keys.contains("iosScannerOptions") == false {
            return CunningScannerOptions()
        }
        
        let scannerOptionsDict = arguments!["iosScannerOptions"] as! Dictionary<String, Any>
        let imageFormat: String = (scannerOptionsDict["imageFormat"] as? String) ?? "png"
        let jpgCompressionQuality: Double = (scannerOptionsDict["jpgCompressionQuality"] as? Double) ?? 1.0
        let noOfPages: Int? = (arguments!["noOfPages"] as? Int)
        return CunningScannerOptions(
            imageFormat: CunningScannerImageFormat(rawValue: imageFormat) ?? .png,
            jpgCompressionQuality: jpgCompressionQuality,
            noOfPages: noOfPages
        )
    }
}
