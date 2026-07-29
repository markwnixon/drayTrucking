//
//  Information.swift
//  drayTrucking
//
//  Created by Mark Nixon on 9/28/25.
//

import SwiftUI
import Foundation

struct InformationView: View {
    @State private var selectedData: AnyView? = nil
    //@State private var isNavigating = false
    //@AppStorage("isLoggedIn") private var isLoggedIn = false  // 👈 Controls login state
    // added Feb 11
    //@AppStorage("jwt_token") private var jwtToken: String = ""
    //@State private var apiResponse = ""
    //@AppStorage("scac") private var scac: String = ""
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedData = selectedData {
                    selectedData
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    //Text("Information View with scac is \(authManager.scac)")
                    Image("\(authManager.scac)logo")
                        .frame(maxHeight: .infinity)
                    
                    Button("Log Out") {
                        authManager.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)                }
                
                HStack {
                    Spacer()
                    //NavigationLink("H", destination: ContentView())
                    Button("R") {
                        selectedData = nil
                    }
                    
                    
                    Spacer()
                    //Button(action: { fetchAPI1() }) {
                    Button(action: { fetchAPI4() }) {
                        Text("DRV")
                                    .font(.headline)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: { fetchAPI5() }) {
                        Text("TRK")
                                    .font(.headline)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: { fetchAPI6() }) {
                        Text("CHS")
                                    .font(.headline)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .buttonStyle(.bordered)
                .padding()
            }
            //.navigationTitle("Data Display App")
        }
    }
    
    
    private func fetchAPI4() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=drivers") { (result: [DriverList]) in
            selectedData = AnyView(APIResponse4View(listData : result))
        }
    }
    
      private func fetchAPI5() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=trucks") { (result: [Trucks]) in
            selectedData = AnyView(APIResponse5View(listData : result))
        }
    }
    
    private func fetchAPI6() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=chassis") { (result: [Chassis]) in
            selectedData = AnyView(APIResponse6View(listData : result))
        }
    }
    

   
}
