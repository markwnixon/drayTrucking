//
//  ScannerView.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/14/25.
//

import SwiftUI
import VisionKit
import PDFKit
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import PencilKit

struct OutContainers: Identifiable, Codable, Hashable {
    let id = UUID()
    let containerNumber: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case containerNumber
        case status
    }
}

struct ScanAndUploadView: View {
    @State private var containers: [OutContainers] = []
    @State private var selectedContainer: OutContainers?
    @State private var showScanner = false
    @State private var showEditor = false
    @State private var editedImage: UIImage?
    @State private var pdfData: Data?
    @State private var isUploading = false
    @State private var uploadMessage: String = ""
    @EnvironmentObject var authManager: AuthManager
    @State private var showSignatureOverlay = false
    @State private var showPODPreview = false

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan Paperwork")
                .font(.title)
                .bold()
            
            Picker("Select Container", selection: $selectedContainer) {
                Text("Choose...").tag(Optional<OutContainers>(nil))
                ForEach(containers) { container in
                    Text("\(container.containerNumber) - \(container.status)")
                        .tag(Optional(container))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // Scan button
            Button("Scan Harcopy Document") {
                #if targetEnvironment(simulator)
                // Simulate a scanned page in simulator
                let size = CGSize(width: 600, height: 800)
                let renderer = UIGraphicsImageRenderer(size: size)
                let fakeImage = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    
                    let text = "Simulated Scan"
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 36),
                        .foregroundColor: UIColor.black
                    ]
                    text.draw(at: CGPoint(x: 50, y: 350), withAttributes: attributes)
                }
                editedImage = fakeImage
                showEditor = true
                #else
                // Real scanner on device
                showScanner = true
                #endif
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedContainer == nil)
            
            Button("Sign Electronic PDF") {
                if let container = selectedContainer {
                    fetchPDF(for: container.containerNumber)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedContainer == nil)
            
            Button("Print Original POD") {
                if let container = selectedContainer {
                    fetchPDFForPrint(container.containerNumber)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedContainer == nil)

            
            if showEditor {
                ScanEditView(image: $editedImage) { processedImage in
                    // Called when user taps "Apply Crop & Contrast"
                    self.editedImage = processedImage
                    generatePDF(from: processedImage)
                    showEditor = false   // dismiss editor
                }
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding()
            }



            
            // PDF preview
            if let data = pdfData {
                PDFPreviewView(data: data)
                    .id(data) // 🔑 Force SwiftUI to reload the PDF when data changes
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .padding()
                
                Button(action: uploadPDF) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Label("Upload PDF", systemImage: "icloud.and.arrow.up")
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Text(uploadMessage)
                .foregroundColor(.secondary)
                .font(.footnote)
            
            Spacer()
        }
        .padding()
        .onAppear(perform: fetchContainers)
        
        // Scanner sheet (for real device)
        .sheet(isPresented: $showScanner) {
            DocumentScannerView { images in
                DispatchQueue.main.async {
                    if let first = images.first {
                        editedImage = first
                        showScanner = false
                        showEditor = true
                    } else {
                        showScanner = false
                    }
                }
            }
        }
        
        .sheet(isPresented: $showSignatureOverlay) {
            if let pdfData = pdfData {
                PDFSignatureOverlayView(pdfData: pdfData) { signedPDF in
                    self.pdfData = signedPDF
                    self.showSignatureOverlay = false
                }
            }
        }
        
        .sheet(isPresented: $showPODPreview) {
            if let data = pdfData {
                PODPrintPreviewView(data: data)
            }
        }

        
    }
    
    private func fetchPDFForPrint(_ containerNumber: String) {
        guard let url = URL(string: "\(authManager.baseURL)get_pdf_for_container?container_number=\(containerNumber)") else {
            print("❌ Invalid URL for container \(containerNumber)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Failed to download PDF: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("⚠️ No data received.")
                return
            }

            DispatchQueue.main.async {
                self.pdfData = data
                self.showPODPreview = true   // 👈 Show preview sheet
            }
        }.resume()
    }
    
    // MARK: - Fetch containers
    private func fetchContainers() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=out_containers") { (result: [OutContainers]) in
            containers = result
        }
    }
    
    // MARK: - Generate PDF
    func generatePDF(from image: UIImage, pageSize: CGSize = CGSize(width: 612, height: 792)) {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        pdfData = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            
            // Calculate aspect-fit rectangle
            let aspectWidth = pageSize.width / image.size.width
            let aspectHeight = pageSize.height / image.size.height
            let scale = min(aspectWidth, aspectHeight)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            // Center the image on the page
            let x = (pageSize.width - scaledSize.width) / 2
            let y = (pageSize.height - scaledSize.height) / 2
            let drawRect = CGRect(origin: CGPoint(x: x, y: y), size: scaledSize)
            
            image.draw(in: drawRect)
        }
    }
    
    @AppStorage("username") private var username: String = ""
    
    // MARK: - Upload PDF
    private func uploadPDF() {
        guard let pdfData = pdfData,
              let container = selectedContainer,
              let url = URL(string: "\(authManager.baseURL)/upload_pdf") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 1️⃣ Add username
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"username\"\r\n\r\n")
        body.append("\(username)\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"container_number\"\r\n\r\n")
        body.append("\(container.containerNumber)\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"scan.pdf\"\r\n")
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n")
        
        isUploading = true
        
        URLSession.shared.uploadTask(with: request, from: body) { _, response, error in
            DispatchQueue.main.async {
                isUploading = false
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    uploadMessage = "✅ Upload successful!"
                } else {
                    uploadMessage = "❌ Upload failed."
                }
            }
        }.resume()
    }
    
    private func fetchPDF(for containerNumber: String) {
        guard let url = URL(string: "\(authManager.baseURL)get_pdf_for_container?container_number=\(containerNumber)") else {
            print("❌ Invalid URL for container \(containerNumber)")
            return
        }

        print("📡 Fetching PDF from URL: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Failed to download PDF: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📨 HTTP status code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("⚠️ No data received from server.")
                return
            }

            DispatchQueue.main.async {
                self.pdfData = data
                self.showSignatureOverlay = true  // new state var
            }
        }.resume()
    }
    

    struct PODPrintPreviewView: View {
        let data: Data
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationStack {
                if let pdfDoc = PDFDocument(data: data) {
                    PDFKitView(pdfDocument: pdfDoc)
                        .padding()
                        .navigationTitle("POD Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") { dismiss() }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button { printPDF() } label: { Image(systemName: "printer") }
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("Unable to preview PDF")
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        
        private func printPDF() {
            guard UIPrintInteractionController.isPrintingAvailable else { return }
            let controller = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)
            info.jobName = "POD Document"
            info.outputType = .general
            controller.printInfo = info
            controller.printingItem = data
            controller.present(animated: true)
        }
    }


    
    
    
    
}


// MARK: - PDF Preview
struct PDFPreviewView: View {
    let data: Data
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if let pdfDocument = PDFDocument(data: data),
                   let firstPage = pdfDocument.page(at: 0) {
                    
                    let pageBounds = firstPage.bounds(for: .mediaBox)
                    let aspectRatio = pageBounds.width / pageBounds.height
                    
                    PDFKitView(pdfDocument: pdfDocument)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding()
                } else {
                    VStack(spacing: 20) {
                        Text("Unable to preview PDF")
                            .font(.headline)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}


// MARK: - Data extension
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}




struct PDFSignatureOverlayView: View {
    let pdfData: Data
    var onSigned: (Data) -> Void

    @State private var signatureImage: UIImage?
    @State private var showSignatureCanvas = false
    @State private var signatureOffset = CGSize.zero
    @State private var signatureScale: CGFloat = 1.0
    @State private var pdfFrame: CGRect = .zero  // actual PDF frame

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                ZStack {
                    PDFPreviewView(data: pdfData)
                        .background(
                            GeometryReader { pdfGeo in
                                Color.clear
                                    .onAppear { pdfFrame = pdfGeo.frame(in: .local) }
                                    .onChange(of: pdfGeo.frame(in: .local)) { newValue, _ in
                                                    pdfFrame = newValue
                                                }
                            }
                        )
                        .cornerRadius(12)
                        .shadow(radius: 4)

                    if let signature = signatureImage {
                        Image(uiImage: signature)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150 * signatureScale)
                            .offset(signatureOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in signatureOffset = value.translation }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in signatureScale = value }
                            )
                            .shadow(radius: 3)
                    }
                }
            }
            .frame(height: 500)
            .padding()

            // Buttons
            HStack {
                Button("Add Signature") {
                    showSignatureCanvas = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                if signatureImage != nil {
                    Button("Save Signed PDF") {
                        guard let signature = signatureImage else { return }

                        let sigFrame = CGRect(
                            x: pdfFrame.midX + signatureOffset.width - (150 * signatureScale)/2,
                            y: pdfFrame.midY + signatureOffset.height - ((150 * signatureScale)*(signature.size.height/signature.size.width))/2,
                            width: 150 * signatureScale,
                            height: 150 * signatureScale * (signature.size.height / signature.size.width)
                        )

                        if let signedPDF = overlaySignatureOnPDFWithTransformUsingDisplayRect(
                            pdfData: pdfData,
                            signature: signature,
                            displayRectInGlobalCoords: pdfFrame,
                            signatureFrameInDisplayCoords: sigFrame,
                            pageBoundsProvider: {
                                if let doc = PDFDocument(data: pdfData),
                                   let page = doc.page(at: 0) {
                                    return page.bounds(for: .mediaBox)
                                }
                                return nil
                            }
                        ) {
                            onSigned(signedPDF)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSignatureCanvas) {
            SignatureCanvasView(signatureImage: $signatureImage) {
                showSignatureCanvas = false
            }
        }
    }
}



// PreferenceKey to capture the PDF preview display frame (in global coords).
struct PDFFrameKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

// Small helper to hold last PDF display frame (we update this from a UIViewRepresentable below)
class PDFFrameReader {
    static var lastPDFFrame: CGRect?
}





/// Draw signature onto PDF using signature frame specified in global (screen) coordinates,
/// and using pdfDisplayRectInGlobal to know where the PDF is drawn on screen.
///
/// pageBoundsProvider returns the PDF page bounds (in PDF points) so we can map correctly.
func overlaySignatureOnPDFWithTransformUsingDisplayRect(
    pdfData: Data,
    signature: UIImage,
    displayRectInGlobalCoords: CGRect,
    signatureFrameInDisplayCoords: CGRect,
    pageBoundsProvider: () -> CGRect?
) -> Data? {

    guard let pageBounds = pageBoundsProvider() else { return nil }

    // PDF page size in points
    let pdfWidth = pageBounds.width
    let pdfHeight = pageBounds.height

    // The PDF is rendered in displayRectInGlobalCoords on screen.
    // Compute the scale from display pixels -> PDF points:
    let scaleX = pdfWidth / displayRectInGlobalCoords.width
    let scaleY = pdfHeight / displayRectInGlobalCoords.height
    // Usually uniform scaling; take X (or average) to be safe:
    let scaleFactor = (scaleX + scaleY) / 2.0

    // Compute signature frame relative to the top-left of the PDF display rect (in screen coords)
    let sigOriginInPDFDisplay = CGPoint(
        x: signatureFrameInDisplayCoords.minX - displayRectInGlobalCoords.minX,
        y: signatureFrameInDisplayCoords.minY - displayRectInGlobalCoords.minY
    )

    // Convert to PDF coordinates (origin bottom-left):
    let sigX_pdf = sigOriginInPDFDisplay.x * scaleFactor
    // y in PDF: PDF origin is bottom-left, screen origin is top-left of display rect,
    // so invert Y:
    let sigY_pdf = (displayRectInGlobalCoords.height - (sigOriginInPDFDisplay.y + signatureFrameInDisplayCoords.height)) * scaleFactor

    let sigWidth_pdf = signatureFrameInDisplayCoords.width * scaleFactor
    let sigHeight_pdf = signatureFrameInDisplayCoords.height * scaleFactor

    let sigRectPDF = CGRect(x: sigX_pdf, y: sigY_pdf, width: sigWidth_pdf, height: sigHeight_pdf)

    // Now render:
    let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        guard let pdfDoc = PDFDocument(data: pdfData),
              let page = pdfDoc.page(at: 0),
              let pageRef = page.pageRef else { return }

        let cgContext = ctx.cgContext

        // Draw PDF page (flip coords)
        cgContext.saveGState()
        cgContext.translateBy(x: 0, y: pdfHeight)
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.drawPDFPage(pageRef)
        cgContext.restoreGState()

        // Draw signature image in PDF coords
        if let cgImage = signature.cgImage {
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pdfHeight)
            cgContext.scaleBy(x: 1.0, y: -1.0)

            cgContext.draw(cgImage, in: sigRectPDF)

            cgContext.restoreGState()
        }
    }

    return data
}








struct SignatureView: View {
    var onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentDrawing = PKDrawing()

    var body: some View {
        VStack {
            CanvasView(drawing: $currentDrawing)
                .cornerRadius(8)
                .shadow(radius: 4)
                .frame(height: 300)
                .padding()

            HStack {
                Button("Clear") {
                    currentDrawing = PKDrawing()
                }
                Spacer()
                Button("Save") {
                    // ✅ Render with transparent background
                    let image = currentDrawing.transparentImage(from: currentDrawing.bounds, scale: 1.0)
                    onSave(image)
                    dismiss()
                }
            }
            .padding()
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvas.backgroundColor = .clear   // ✅ Transparent background
        canvas.isOpaque = false            // ✅ Important for transparency
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

extension PKDrawing {
    /// Renders a transparent UIImage of the drawing for the given rect/scale.
    func transparentImage(from rect: CGRect, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false   // keep alpha
        
        let renderer = UIGraphicsImageRenderer(bounds: rect, format: format)
        return renderer.image { ctx in
            // ensure background is clear
            UIColor.clear.setFill()
            ctx.fill(rect)
            
            // ask PKDrawing for a UIImage and draw it into the renderer context
            let drawingImage = self.image(from: rect, scale: scale)
            drawingImage.draw(in: rect)
        }
    }
}


struct PDFPreviewWithSignature: View {
    let pdfData: Data
    let signature: UIImage

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PDFPreviewView(data: pdfData)
            
            // inside ZStack just after PDFPreviewView(...)
            PDFFrameReporter()
                .frame(width: 1, height: 1) // invisible helper

            
            // Signature overlay in bottom-right corner
            Image(uiImage: signature)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 100)
                .padding(.trailing, 40)
                .padding(.bottom, 40)
                .shadow(radius: 3)
        }
    }
}


struct SignatureCanvasView: View {
    @Binding var signatureImage: UIImage?
    var onSave: (() -> Void)? = nil  // callback when signature is saved
    
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    @State private var lastPoint: CGPoint? = nil
    
    var body: some View {
        VStack {
            ZStack {
                Color.white
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                ForEach(0..<paths.count, id: \.self) { i in
                    paths[i]
                        .stroke(Color.black, lineWidth: 2)
                }
                
                currentPath
                    .stroke(Color.black, lineWidth: 2)
            }
            .gesture(
                DragGesture(minimumDistance: 0.1)
                    .onChanged { value in
                        if lastPoint != nil {
                            currentPath.addLine(to: value.location)
                        } else {
                            currentPath.move(to: value.location)
                        }
                        lastPoint = value.location

                    }
                    .onEnded { _ in
                        paths.append(currentPath)
                        currentPath = Path()
                        lastPoint = nil
                    }
            )
            
            HStack {
                Button("Clear") {
                    paths.removeAll()
                    currentPath = Path()
                    signatureImage = nil
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save Signature") {
                    saveSignatureAsImage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(height: 300)
        .padding()
    }
    
    private func saveSignatureAsImage() {
        // Use the actual view width/height
        let canvasWidth: CGFloat =  UIScreen.main.bounds.width - 32 // match sheet padding
        let canvasHeight: CGFloat = 300 // same as sheet height

        let renderer = ImageRenderer(content:
            ZStack {
                Color.clear
                ForEach(0..<paths.count, id: \.self) { i in
                    paths[i]
                        .stroke(Color.black, lineWidth: 2)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            .padding(8) // optional: adds safe margin so strokes at the edges are not clipped
        )

        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false

        if let uiImage = renderer.uiImage {
            signatureImage = uiImage
            print("✅ Signature captured successfully")
            onSave?()
        } else {
            print("❌ Failed to capture signature image")
        }
    }


}

struct PDFFrameReporter: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        // Walk up to find the nearest superview that is hosting SwiftUI content and get its window coordinates
        DispatchQueue.main.async {
            if let superview = uiView.superview {
                let globalFrame = superview.convert(uiView.frame, to: nil)
                PDFFrameReader.lastPDFFrame = globalFrame
            }
        }
    }
}
