//
//  Calendar.swift
//  drayTrucking
//
//  Created by Mark Nixon on 2/4/25.
//
//
import SwiftUI

struct Calendar: Codable {
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
    let calDate: Date
    let calMessage: String
    let delType: String
}

struct APIResponse2View: View {
    let listData : [Calendar]
    //Sort the active container data by status then shipper
    //var sortedItems: [Calendar] {
    //return listData.sorted { ($0.gateOut, $0.status) < ($1.gateOut, $1.status) }
    // }
    
    
    var body: some View {
        NavigationView {
            
            List{
                ForEach(Array(listData.enumerated()), id: \.element.id) { index, item in
                    
                        if index == 0 || item.calDate != listData[index - 1].calDate {
                            VStack(alignment: .leading) {
                                let fdate = item.calDate.formatted(.dateTime.month().day())
                                Text(fdate).font(.headline).bold().foregroundColor(.red)                            }
                        }
                    
                        NavigationLink(destination: CalDetailView(item: item)){
                        VStack(alignment: .leading) {
                            //Text(item.container).font(.headline)
                            //Text(item.date, format: .dateTime.year().month().day()).font(.subheadline)
                            //Test various date formats for output, next is just month and day...
                            Text(item.container).font(.headline)
                            Text(item.calMessage).font(.subheadline)
                            //Text(item.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                        }
                    }
                }
                .navigationTitle("Calendar")
            }
        }
    }
}

// Detail View
struct CalDetailView: View {
    let item: Calendar

    
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

