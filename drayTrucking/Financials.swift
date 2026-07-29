//
//  Financials.swift
//  api test six
//
//  Created by Mark Nixon on 6/15/25.
//
import SwiftUI

struct Financials: Codable {
    let id: Int
    let company: String
    let ototal: String
    let duenow: String
}

struct APIResponse3View: View {
    //@State private var listData: [ContainersOut] = []
    let listData : [Financials]
        var body: some View {
            NavigationStack {
                List(listData, id: \.id) { item in
                    VStack(alignment: .leading) {
                        Text(item.company).font(.headline)
                        Text("Open: \(item.ototal)").font(.subheadline)
                        Text("Due:\(item.duenow)").font(.subheadline)                    }
                }
                .navigationTitle("Open Balance Report")
                }
            }
        }

