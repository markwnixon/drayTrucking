//
//  ScannerController.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/14/25.
//

import SwiftUI
import VisionKit
import PDFKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var completion: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var completion: ([UIImage]) -> Void
        init(completion: @escaping ([UIImage]) -> Void) { self.completion = completion }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            completion(images)
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completion([])
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completion([])
            controller.dismiss(animated: true)
        }
    }



    // MARK: Mock PDF
    private func makeMockPDF() -> Data? {
        let pdf = PDFDocument()
        let text = "Simulated Scan\n\nThis is a mock document for simulator testing."
        let page = PDFPage(image: textToImage(text))
        pdf.insert(page!, at: 0)
        return pdf.dataRepresentation()
    }

    private func textToImage(_ text: String) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        UIGraphicsBeginImageContext(size)
        UIColor.white.set()
        UIRectFill(CGRect(origin: .zero, size: size))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .paragraphStyle: paragraphStyle
        ]
        text.draw(in: CGRect(x: 10, y: 100, width: 280, height: 200), withAttributes: attrs)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}


