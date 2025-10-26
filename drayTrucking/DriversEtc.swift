//
//  DriversEtc.swift
//  drayTrucking
//
//  Created by Mark Nixon on 9/28/25.
//

import SwiftUI

struct DriverList: Codable {
    let id: Int
    let name: String
    let phone: String
    let email: String
    let cdl: String
}

struct Trucks: Codable {
    let id: Int
    let name: String
    let phone: String
    let email: String
    let cdl: String
}

struct Chassis: Codable {
    let id: Int
    let name: String
    let phone: String
    let email: String
    let cdl: String
}


struct APIResponse4View: View {
    @EnvironmentObject var authManager: AuthManager
    let listData : [DriverList]
    
    var body: some View {
        NavigationView {
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
        NavigationView {
            List(listData, id: \.id) { item in
                NavigationLink(destination: TruckDetailView(item: item)){
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
        NavigationView {
            List(listData, id: \.id) { item in
                NavigationLink(destination: ChassisDetailView(item: item)){
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
                .navigationTitle("Chassis Information")
            }
        }
    }// Detail View


struct DriverDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let item: DriverList
    var body: some View {
        
        VStack(spacing: 30) {
            
            Text(item.name)
                .font(.body)
                .fontWeight(.bold)
            Text(item.cdl)
                .font(.body)
                .fontWeight(.bold)
            Text(item.phone)
                .font(.body)
            Text(item.email)
                .font(.body)
            
            AsyncImage(url: URL(string: "\(authManager.baseURL)static/cdl/\(item.name).png"))
            {image in image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Color.red
            }
            .frame(maxWidth: 375, maxHeight: 375)
        }
        .padding()
        .navigationTitle("Driver Details")
    }
}

struct TruckDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let item: Trucks
    var body: some View {
        
        VStack(spacing: 30) {
            
            Text(item.name)
                .font(.body)
                .fontWeight(.bold)
            Text(item.cdl)
                .font(.body)
                .fontWeight(.bold)
            Text(item.phone)
                .font(.body)
            Text(item.email)
                .font(.body)
            
            AsyncImage(url: URL(string: "\(authManager.baseURL)static/cdl/\(item.name).png"))
            {image in image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Color.red
            }
            .frame(maxWidth: 375, maxHeight: 375)
        }
        .padding()
        .navigationTitle("Driver Details")
    }
}

struct ChassisDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let item: Chassis
    var body: some View {
        
        VStack(spacing: 30) {
            
            Text(item.name)
                .font(.body)
                .fontWeight(.bold)
            Text(item.cdl)
                .font(.body)
                .fontWeight(.bold)
            Text(item.phone)
                .font(.body)
            Text(item.email)
                .font(.body)
            
            AsyncImage(url: URL(string: "\(authManager.baseURL)static/cdl/\(item.name).png"))
            {image in image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Color.red
            }
            .frame(maxWidth: 375, maxHeight: 375)
        }
        
        .padding()
        .navigationTitle("Driver Details")
    }
}

