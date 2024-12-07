import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var resultChannel: FlutterResult?
    var presentingController: UIViewController?
    var scannerOptions: CunningScannerOptions = CunningScannerOptions()
    var maxPages: Int = 100
    var isGalleryImportAllowed: Bool = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cunning_document_scanner", binaryMessenger: registrar.messenger())
        let instance = SwiftCunningDocumentScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPictures" {
            let args = call.arguments as? [String: Any]
            scannerOptions = CunningScannerOptions.fromArguments(args: args)
            maxPages = args?["noOfPages"] as? Int ?? 100
            isGalleryImportAllowed = args?["isGalleryImportAllowed"] as? Bool ?? false

            presentingController = UIApplication.shared.keyWindow?.rootViewController
            self.resultChannel = result

            if isGalleryImportAllowed {
                presentGalleryPicker()
            } else if VNDocumentCameraViewController.isSupported {
                let documentCamera = VNDocumentCameraViewController()
                documentCamera.delegate = self
                presentingController?.present(documentCamera, animated: true)
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "Document camera is not available on this device", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    func presentGalleryPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        presentingController?.present(imagePicker, animated: true)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            let tempDirPath = self.getDocumentsDirectory()
            let currentDateTime = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd-HHmmss"
            let formattedDate = df.string(from: currentDateTime)
            let url = tempDirPath.appendingPathComponent("\(formattedDate).\(scannerOptions.imageFormat.rawValue)")

            switch scannerOptions.imageFormat {
            case .jpg:
                try? pickedImage.jpegData(compressionQuality: scannerOptions.jpgCompressionQuality)?.write(to: url)
            case .png:
                try? pickedImage.pngData()?.write(to: url)
            }

            resultChannel?([url.path])
        } else {
            resultChannel?(nil)
        }
        presentingController?.dismiss(animated: true)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let tempDirPath = self.getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        var filenames: [String] = []

        for i in 0 ..< min(scan.pageCount, maxPages) {
            let page = scan.imageOfPage(at: i)
            let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).\(scannerOptions.imageFormat.rawValue)")
            switch scannerOptions.imageFormat {
            case .jpg:
                try? page.jpegData(compressionQuality: scannerOptions.jpgCompressionQuality)?.write(to: url)
            case .png:
                try? page.pngData()?.write(to: url)
            }

            filenames.append(url.path)
        }
        resultChannel?(filenames)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        resultChannel?(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        presentingController?.dismiss(animated: true)
    }
}
