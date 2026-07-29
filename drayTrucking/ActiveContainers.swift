//
//  ActiveContainers.swift
//  drayTrucking
//
//  Created by Mark Nixon on 2/4/25.
//

import SwiftUI

struct ContainersOut: Codable {
    let id: Int
    let container: String
    let shipper: String
    let status: String
    let jo: String
    let scac: String
    let release: String
    let haulType: String
    let delAddress: String
    let delivery: Date
    let dueBack: Date
    let gateIn: Date
    let gateOut: Date
    let portEarly: Date
    let portLate: Date
}

struct APIResponse1View: View {
    //@State private var listData: [ContainersOut] = []
    let listData : [ContainersOut]

    //Sort the active container data by status then shipper
    var sortedItems: [ContainersOut] {
            return listData.sorted { ($0.status, $0.shipper) < ($1.status, $1.shipper) }
    }
    
    //Allow filtering of the data by container status
    @State private var selectedCategory = "All Active"
    let categories = ["All Active", "Unpulled", "Out", "Returned"]
    
    var filteredItems: [ContainersOut] {
        if selectedCategory == "All Active" {
            return sortedItems
        } else {
            return sortedItems.filter { $0.status == selectedCategory }
        }
    }
    func statusColor(for status: String) -> Color {
        switch status {
        case "Unpulled": return Color.primary       // adapts automatically
        case "Out": return Color.accentColor        // uses your app's accent
        case "Returned": return Color.secondary     // softer color, adaptive
        default: return Color.primary
        }
    }

    
        var body: some View {
            NavigationStack {
                
                VStack {
                    // Picker for selecting category
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .pickerStyle(WheelPickerStyle()) // Scroll wheel style
                    .frame(height: 100) // Adjust height to show full wheel
                    
                    
                    List(filteredItems, id: \.id) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            VStack(alignment: .leading) {
                                let titletext = item.container == "Unpulled Export" ? item.release : item.container
                                Text(titletext)
                                    .foregroundColor(statusColor(for: item.status))
                                    .font(.headline)
                                Text(item.shipper)
                                    .foregroundColor(statusColor(for: item.status))
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .navigationTitle("\(selectedCategory) Containers ")
                }
            }
        }


// Detail View
struct ItemDetailView: View {
    let item: ContainersOut

    
    var body: some View {
                
        VStack(spacing: 10) {
            
            let titletext = item.container == "Unpulled Export" ? item.release : item.container
            let subtitletext = item.container == "Unpulled Export" ? "Export Unpulled" : "\(item.haulType) \(item.status)"
            
            Text(titletext)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(subtitletext)
                .font(.title)
                .fontWeight(.bold)
            Text(item.shipper)
                .font(.body)
            Text(item.delAddress)
                .font(.body)
        }
        .padding()
        .navigationTitle("Job Details")
            
            
            let phrase1 = item.status == "Unpulled" ? "Est Pull:" : "Pulled On:"
            let phrase2 = item.status == "Returned" ? "Returned On:" : "Est Return:"
            
            let phrase3 = item.haulType.contains("Export") ? "ERD:" : "1st Avail:"
            let phrase4 = item.haulType.contains("Export") ? "Cutoff:" : "LFD:"
            
            let phrase5 = item.status == "Unpulled" ? "Est Delivery:" : "Deliver On:"
            let phrase6 = item.status == "Unpulled" ? "Est Due Back:" : "Due Back:"
                        
            let goDate = item.gateOut.formatted(.dateTime.year()) == "1900" ? "??" : item.gateOut.formatted(.dateTime.month().day())
            let giDate = item.gateIn.formatted(.dateTime.year()) == "1900" ? "??" : item.gateIn.formatted(.dateTime.month().day())
            
            let eDate = item.portEarly.formatted(.dateTime.year()) == "1900" ? "??" : item.portEarly.formatted(.dateTime.month().day())
            let lDate = item.portLate.formatted(.dateTime.year()) == "1900" ? "??" : item.portLate.formatted(.dateTime.month().day())
            
            let delDate = item.delivery.formatted(.dateTime.year()) == "1900" ? "??" : item.delivery.formatted(.dateTime.month().day())
            let dueDate = item.dueBack.formatted(.dateTime.year()) == "1900" ? "??" : item.dueBack.formatted(.dateTime.month().day())
            
        VStack(spacing: 10) {
            HStack{
                Spacer()
                Text(phrase1).bold()
                Text(goDate)
                Spacer()
                Text(phrase2).bold()
                Text(giDate)
                Spacer()
            }
            HStack{
                Spacer()
                Text(phrase3).bold()
                Text(eDate)
                Spacer()
                Text(phrase4).bold()
                Text(lDate)
                Spacer()
            }
            HStack{
                Spacer()
                Text(phrase5).bold()
                Text(delDate)
                Spacer()
                Text(phrase6).bold()
                Text(dueDate)
                Spacer()
            }
            
            Spacer()
            Text("JO: \(item.jo)")
            Text("Original Release: \(item.release)")
            
        }
        .padding()

    }
}

