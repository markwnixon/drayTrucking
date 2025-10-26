//
//  drayTruckingApp.swift
//  drayTrucking
//
//  Created by Mark Nixon on 2/4/25.
//

import SwiftUI

@main
struct drayTruckingApp: App {
    //@AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("scac") private var scac = ""
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                //Text("Contentview Is logged in is \(authManager.isAuthenticated) and scac is \(scac)")
                ContentView()
                    .environmentObject(authManager)
            } else {
                //Text("Loginview Is logged in is \(authManager.isAuthenticated) and scac is \(scac)")
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
    
    
