//
//  ScanEditView.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/18/25.
//
import SwiftUI
import VisionKit
import PDFKit
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins


struct ScanEditView: View {
    @Binding var image: UIImage?
    var onDone: (UIImage) -> Void   // ✅ new callback
    @State private var contrast: Double = 1.0
    //@State private var croppedRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    let context = CIContext()

    var body: some View {
        VStack {
            if let img = image {
                //Image(uiImage: processedImage(from: img))
                Image(uiImage: processedImage(to: img))
                    .resizable()
                    .scaledToFit()
                    //.overlay(
                    //    Rectangle()
                    //        .stroke(Color.blue, lineWidth: 2)
                    //        .frame(width: 200 * croppedRect.width, height: 300 * croppedRect.height)
                   //        .position(x: 200 * croppedRect.midX, y: 300 * croppedRect.midY)
                   // )
            }

            Slider(value: $contrast, in: 0.5...2.0, step: 0.1) {
                Text("Contrast")
            }
            .padding()

            Button("Apply Contrast") {
                if let img = image {
                    //let newImage = applyCropAndContrast(to: img)
                    let newImage = processedImage(to: img)
                    image = newImage
                    onDone(newImage)   // ✅ call back to parent immediately
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func processedImage(to img: UIImage) -> UIImage {
        let ciImage = CIImage(image: img)!
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = Float(contrast)
        if let output = filter.outputImage,
           let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return img
    }

   // private func applyCropAndContrast(to img: UIImage) -> UIImage {
      //  let processed = processedImage(from: img)
        //let width = processed.size.width
        //let height = processed.size.height
        //let cropRectScaled = CGRect(x: croppedRect.origin.x * width,
        //                            y: croppedRect.origin.y * height,
        //                            width: croppedRect.width * width,
        //                            height: croppedRect.height * height)
        //if let cgImage = processed.cgImage?.cropping(to: cropRectScaled) {
         //   return UIImage(cgImage: cgImage)
       // }
     //   return processed
    //}
}




