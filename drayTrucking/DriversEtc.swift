//
//  DriversEtc.swift
//  drayTrucking
//
//  Created by Mark Nixon on 9/28/25.
//

import SwiftUI
import PDFKit


struct PDFKitView2: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Handle remote and local files differently
        if url.isFileURL {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            } else {
                print("⚠️ Failed to open local PDF:", url)
            }
        } else {
            // Download from remote URL
            downloadAndDisplayPDF(from: url, in: pdfView)
        }
    }

    private func downloadAndDisplayPDF(from remoteURL: URL, in pdfView: PDFView) {
        // 🔍 Start download
        print("⬇️ Starting download from:", remoteURL.absoluteString)
        
        let task = URLSession.shared.dataTask(with: remoteURL) { data, response, error in
            
            // 🔍 Check for network error
            if let error = error {
                print("⚠️ Download error:", error.localizedDescription)
                return
            }
            
            // 🔍 Print response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📄 HTTP status:", httpResponse.statusCode)
                print("📄 MIME type:", httpResponse.mimeType ?? "nil")
            } else {
                print("⚠️ No valid HTTP response")
            }
            
            // 🔍 Print how many bytes were received
            print("📦 Bytes received:", data?.count ?? 0)
            
            // Now handle the data
            guard let data = data else {
                print("⚠️ No data received for:", remoteURL)
                return
            }
            
            DispatchQueue.main.async {
                if let document = PDFDocument(data: data) {
                    pdfView.document = document
                    print("✅ PDF loaded successfully for:", remoteURL.lastPathComponent)
                } else {
                    print("⚠️ Failed to create PDFDocument from data:", remoteURL)
                }
            }
        }
        task.resume()
    }

}



struct DriverList: Codable {
    let id: Int
    let name: String
    let phone: String
    let email: String
    let cdl: String
}

struct Trucks: Codable {
    let id: Int
    let unit: String
    let vin: String
    let year: String
    let make: String
    let model: String
    let color: String
    let odom: String
    let weight: String
    let ezpass: String
    let portx: String
}

struct Chassis: Codable {
    let id: Int
    let unit: String
    let length: String
    let plate: String
    let atag: String
    let color: String
    let weight: String
}


struct APIResponse4View: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("scac") private var scac = ""
    
    let listData : [DriverList]
    
    var body: some View {
        NavigationStack {
            List(listData, id: \.id) { item in
                NavigationLink(destination: DriverDetailView(item: item)){
                    VStack(alignment: .leading) {
                            //Text(item.container).font(.headline)
                            //Text(item.date, format: .dateTime.year().month().day()).font(.subheadline)
                            //Test various date formats for output, next is just month and day...
                            Text(item.name).font(.headline)
                            Text(item.phone).font(.subheadline)
                            Text(item.email).font(.subheadline)
                            Text(item.cdl).font(.subheadline)
                        }
                    }
                }
                .navigationTitle("Driver Information")
            }
        }
    }

struct APIResponse5View: View {
    let listData : [Trucks]
    
    //Sort the active container data by status then shipper
    //var sortedItems: [Calendar] {
    //return listData.sorted { ($0.gateOut, $0.status) < ($1.gateOut, $1.status) }
    // }
    
    var body: some View {
        NavigationStack {
            List(listData, id: \.id) { item in
                NavigationLink(destination: TruckDetailView(item: item)){
                    VStack(alignment: .leading) {
                            //Text(item.container).font(.headline)
                            //Text(item.date, format: .dateTime.year().month().day()).font(.subheadline)
                            //Test various date formats for output, next is just month and day...
                            Text("Unit: \(item.unit)").font(.headline)
                            Text("VIN: \(item.vin)").font(.subheadline)
                            Text("Year: \(item.year)").font(.subheadline)
                            Text("Make: \(item.make)").font(.subheadline)
                            Text("Model: \(item.model)").font(.subheadline)
                        }
                    }
                }
                .navigationTitle("Truck Information")
            }
        }
    }

struct APIResponse6View: View {
    let listData : [Chassis]
    
    //Sort the active container data by status then shipper
    //var sortedItems: [Calendar] {
    //return listData.sorted { ($0.gateOut, $0.status) < ($1.gateOut, $1.status) }
    // }
    
    var body: some View {
        NavigationStack {
            List(listData, id: \.id) { item in
                NavigationLink(destination: ChassisDetailView(item: item)){
                    VStack(alignment: .leading) {
                            //Text(item.container).font(.headline)
                            //Text(item.date, format: .dateTime.year().month().day()).font(.subheadline)
                            //Test various date formats for output, next is just month and day...
                            Text("Chassis: \(item.unit)").font(.headline)
                            Text("Length: \(item.length)").font(.subheadline)
                            Text("Plate: \(item.plate)").font(.subheadline)
                            Text("E-Tag: \(item.atag)").font(.subheadline)
                        }
                    }
                }
                .navigationTitle("Chassis Information")
            }
        }
    }// Detail View


struct DriverDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("scac") private var scac = ""
    
    let item: DriverList
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // --- Driver Info ---
                VStack(spacing: 6) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(item.cdl)
                        .font(.body)
                        .fontWeight(.semibold)
                    Text(item.phone)
                    Text(item.email)
                }

                // --- CDL PDF ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("CDL")
                        .font(.headline)
                    if let pdfURL = makePDFURL(suffix: "_CDL.pdf") {
                        PDFKitView2(url: pdfURL)
                            .frame(width: 375, height: 375)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .onAppear{
                                print("✅ CDL URL created:", pdfURL)
                            }
                    } else {
                        Text("CDL PDF not found")
                            .foregroundColor(.red)
                    }
                }

                // --- Medical Card PDF ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medical Card")
                        .font(.headline)
                    if let pdfURL = makePDFURL(suffix: "_MED.pdf") {
                        PDFKitView2(url: pdfURL)
                            .frame(width: 375, height: 375)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                    } else {
                        Text("Medical Card PDF not found")
                            .foregroundColor(.red)
                    }
                }

                // --- TWIC Card PDF ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("TWIC Card")
                        .font(.headline)
                    if let pdfURL = makePDFURL(suffix: "_TWIC.pdf") {
                        PDFKitView2(url: pdfURL)
                            .frame(width: 375, height: 375)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                    } else {
                        Text("TWIC Card PDF not found")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Driver Details")
    }
    
    private func makePDFURL(suffix: String) -> URL? {
        let cleanName = item.name.replacingOccurrences(of: " ", with: "")
        let basePath = "\(authManager.baseURL)static/\(scac)/data/vCompliance/"
        let fullPath = basePath + "\(cleanName)\(suffix)"
        print("🔍 Checking PDF path:", fullPath)
        return URL(string: fullPath)
    }

}



struct TruckDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("scac") private var scac = ""
    let item: Trucks
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                Text("Unit: \(item.unit)")
                Text("VIN: \(item.vin)")
                Text("Year: \(item.year)")
                Text("Make: \(item.make)")
                Text("Model: \(item.model)")
                Text("Color: \(item.color)")
                Text("Odometer: \(item.odom)")
                Text("Weight: \(item.weight)")
                Text("EZpass Xponder: \(item.ezpass)")
                Text("Port Xponder: \(item.portx)")
                
                
                // --- Truck PDF ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Truck Registration")
                        .font(.headline)
                    if let pdfURL = makePDFURL(suffix: "_Reg.pdf") {
                        PDFKitView2(url: pdfURL)
                            .frame(width: 375, height: 375)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .onAppear{
                                print("✅ Truck URL created:", pdfURL)
                            }
                    } else {
                        Text("Truck PDF not found")
                            .foregroundColor(.red)
                    }
                }
                
                
                
            }
            .padding()
        }
            .navigationTitle("Truck Details")
        }
        
        private func makePDFURL(suffix: String) -> URL? {
            let cleanName = item.unit.replacingOccurrences(of: " ", with: "")
            let basePath = "\(authManager.baseURL)static/\(scac)/data/vCompliance/"
            let fullPath = basePath + "Unit_\(cleanName)\(suffix)"
            print("🔍 Checking PDF path:", fullPath)
            return URL(string: fullPath)
        }
    
}

struct ChassisDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("scac") private var scac = ""
    let item: Chassis
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                Text("Unit: \(item.unit)")
                Text("Length: \(item.length)")
                Text("Plate: \(item.plate)")
                Text("E-tag: \(item.atag)")
                Text("Color: \(item.color)")
                Text("Weight: \(item.weight)")
                
                // --- Chassis PDF ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chassis Registration")
                        .font(.headline)
                    if let pdfURL = makePDFURL(suffix: "_Reg.pdf") {
                        PDFKitView2(url: pdfURL)
                            .frame(width: 375, height: 375)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .onAppear{
                                print("✅ Chassis URL created:", pdfURL)
                            }
                    } else {
                        Text("Chassis PDF not found")
                            .foregroundColor(.red)
                    }
                }
                
            }
            
            .padding()
        }
        .navigationTitle("Chassis Details")
    }
    
    private func makePDFURL(suffix: String) -> URL? {
        let cleanName = item.unit.replacingOccurrences(of: " ", with: "")
        let basePath = "\(authManager.baseURL)static/\(scac)/data/vCompliance/"
        let fullPath = basePath + "Unit_\(cleanName)\(suffix)"
        print("🔍 Checking PDF path:", fullPath)
        return URL(string: fullPath)
    }
    
}
