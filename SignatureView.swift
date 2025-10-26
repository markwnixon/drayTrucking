//
//  HandWriting.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/25/25.
//

import SwiftUI

struct SignatureView: View {
    @Binding var signatureImage: UIImage?

    @State private var currentPath = Path()
    @State private var paths: [Path] = []

    var body: some View {
        ZStack {
            Color.white
                .overlay(
                    Canvas { context, size in
                        for path in paths {
                            context.stroke(path, with: .color(.black), lineWidth: 2)
                        }
                        context.stroke(currentPath, with: .color(.black), lineWidth: 2)
                    }
                )
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if currentPath.isEmpty {
                            currentPath.move(to: value.location)
                        } else {
                            currentPath.addLine(to: value.location)
                        }
                    }
                    .onEnded { _ in
                        paths.append(currentPath)
                        currentPath = Path()
                    }
                )
        }
        .navigationTitle("Add Signature")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    signatureImage = renderSignature()
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear") {
                    paths.removeAll()
                    currentPath = Path()
                }
            }
        }
    }

    private func renderSignature() -> UIImage? {
        let controller = UIHostingController(rootView:
            ZStack {
                Color.white
                Canvas { context, size in
                    for path in paths {
                        context.stroke(path, with: .color(.black), lineWidth: 2)
                    }
                }
            }
        )
        let view = controller.view
        let targetSize = CGSize(width: 400, height: 200)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}


import PDFKit

func overlaySignatureOnPDF(pdfData: Data, signature: UIImage, at position: CGPoint) -> Data? {
    guard let pdf = PDFDocument(data: pdfData),
          let page = pdf.page(at: 0) else { return nil }

    let pageBounds = page.bounds(for: .mediaBox)

    // Create PDF data context
    let pdfRenderer = NSMutableData()
    UIGraphicsBeginPDFContextToData(pdfRenderer, pageBounds, nil)

    for i in 0..<pdf.pageCount {
        guard let page = pdf.page(at: i) else { continue }
        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
        guard let ctx = UIGraphicsGetCurrentContext() else { continue }

        ctx.saveGState()
        ctx.translateBy(x: 0, y: pageBounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()

        // Draw signature on first page
        if i == 0 {
            let sigRect = CGRect(origin: position, size: CGSize(width: 150, height: 50))
            signature.draw(in: sigRect)
        }
    }

    UIGraphicsEndPDFContext()
    return pdfRenderer as Data
}



