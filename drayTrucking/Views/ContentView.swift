//
//  ContentView.swift
//  api test six
//
//  Created by Mark Nixon on 2/1/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var selectedData: AnyView? = nil
    //@State private var isNavigating = false
    //@AppStorage("isLoggedIn") private var isLoggedIn = false  // 👈 Controls login state
    // added Feb 11
    //@AppStorage("jwt_token") private var jwtToken: String = ""
    @AppStorage("scac") private var scac: String = ""
    //@State private var apiResponse = ""
    
    //@StateObject private var authManager = AuthManager()
    @EnvironmentObject var authManager: AuthManager
    @State private var refreshKey = UUID()
    @State private var signatureImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                
                //YourContentView(refreshKey: refreshKey)
                
                if let selectedData = selectedData {
                    selectedData
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    //Text("Content View with scac is \(scac)")
                    Image("\(scac)logo")
                        .frame(maxHeight: .infinity)
                    
                    Button("Log Out") {
                        authManager.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                }
                
                HStack {
                    Spacer()
                    Button {
                        selectedData = nil
                    } label: {
                        Image("home")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    NavigationLink(destination: PinAssignmentView())
                    {
                        Image("pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    NavigationLink(destination: ScanAndUploadView())
                    {
                        Image("scan")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                   // NavigationLink(destination: SignAndUploadView())
                   // {
                   //     Image("signature")
                   //         .resizable()
                   //         .scaledToFit()
                   //         .frame(width: 40, height: 40) // Adjust size as needed
                   // }
                   // .buttonStyle(.plain)
                    
                    
                    Spacer()

                    Button(action: { fetchAPI1() }) {
                        Image("container")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50) // Adjust size as needed
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: { fetchAPI2() }) {
                        Image("calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: { fetchAPI3() }) {
                        Image("dollar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    NavigationLink(destination: InformationView())
                    {
                        Image("info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
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
    
    private func fetchAPI1() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=active_containers") { (result: [ContainersOut]) in
            selectedData = AnyView(APIResponse1View(listData : result))
        }
    }
    
    private func fetchAPI2() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=calendar") { (result: [Calendar]) in
            selectedData = AnyView(APIResponse2View(listData : result))
        }
    }
    private func fetchAPI3() {
        authManager.fetchAPI(url: "\(authManager.baseURL)get_api_data?data_needed=financials") { (result: [Financials]) in
                selectedData = AnyView(APIResponse3View(listData : result))
            }
        }
    
}
    
    
    
    






struct APIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


#Preview {
    ContentView()
}

