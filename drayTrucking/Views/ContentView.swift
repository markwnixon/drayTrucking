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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesExpandedLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                //YourContentView(refreshKey: refreshKey)
                
                if let selectedData = selectedData {
                    selectedData
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    //Text("Content View with scac is \(scac)")
                    Image("\(scac)logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: usesExpandedLayout ? 560 : 320)
                        .frame(maxHeight: .infinity)
                        .padding(usesExpandedLayout ? 40 : 16)
                    
                    Button("Log Out") {
                        authManager.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                }
                
                HStack(spacing: usesExpandedLayout ? 24 : 8) {
                    Spacer()
                    Button {
                        selectedData = nil
                    } label: {
                        Image("home")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    NavigationLink(destination: PinAssignmentView())
                    {
                        Image("pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    NavigationLink(destination: ScanAndUploadView())
                    {
                        Image("scan")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
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
                            .frame(width: usesExpandedLayout ? 56 : 42,
                                   height: usesExpandedLayout ? 56 : 42)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: { fetchAPI2() }) {
                        Image("calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: { fetchAPI3() }) {
                        Image("dollar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    NavigationLink(destination: InformationView())
                    {
                        Image("info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: usesExpandedLayout ? 48 : 36,
                                   height: usesExpandedLayout ? 48 : 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, usesExpandedLayout ? 32 : 12)
                .padding(.vertical, 12)
                .background(.bar)
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
