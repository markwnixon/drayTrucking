//
//  Pinmaker.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/11/25.
//

import SwiftUI

struct PinAssignmentView: View {
    @State private var drivers: [Driver] = []
    @State private var trucks: [Truck] = []
    @State private var ingates: [InGate] = []
    @State private var outgates: [OutGate] = []
    @State private var pintimes: [PinTime] = []
    
    @State private var selectedDriver: Driver?
    @State private var selectedTruck: Truck?
    @State private var selectedInGate: InGate?
    @State private var selectedOutGate: OutGate?
    @State private var selectedPinTime: PinTime?
    
    @AppStorage("scac") private var scac: String = ""
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            Form {
                //Section(header: Text("Select Driver")) {
                Section {
                    Picker("Driver", selection: $selectedDriver) {
                        Text("Select a driver").tag(Optional<Driver>.none)
                        ForEach(drivers, id: \.id) { driver in
                            Text(driver.name).tag(Optional(driver))
                        }
                    }
                }
                
                
                //Section(header: Text("Select Truck")) {
                Section {
                    Picker("Truck", selection: $selectedTruck) {
                        Text("Select a truck").tag(Optional<Truck>.none)
                        ForEach(trucks, id: \.id) { truck in
                            Text(truck.unit).tag(Optional(truck))
                        }
                    }
                }
                
                //Section(header: Text("Select In-Gate")) {
                Section {
                    Picker("InGate", selection: $selectedInGate) {
                        Text("Select an InGate").tag(Optional<InGate>.none)
                        ForEach(ingates, id: \.id) { ingate in
                            Text(ingate.unit).tag(Optional(ingate))
                        }
                    }
                }
                
                //Section(header: Text("Select Out-Gate")) {
                Section {
                    Picker("OutGate", selection: $selectedOutGate) {
                        Text("Select an OutGate").tag(Optional<OutGate>.none)
                        ForEach(outgates, id: \.id) { outgate in
                            Text(outgate.unit).tag(Optional(outgate))
                        }
                    }
                }
                
                //Section(header: Text("Select Time")) {
                Section {
                    Picker("Time", selection: $selectedPinTime) {
                        Text("Select desired Time").tag(Optional<PinTime>.none)
                        ForEach(pintimes, id: \.id) { pintime in
                            Text(pintime.name).tag(Optional(pintime))
                        }
                    }
                }
                
                Button("Submit Assignment") {
                    submitAssignment()
                }
                .disabled(selectedDriver == nil || selectedTruck == nil || selectedInGate == nil || selectedOutGate == nil || selectedPinTime == nil)
            }
            .navigationTitle("Set Up Pin Reservation")
            .onAppear(perform: loadData)
        }
    }

    func loadData() {
            guard let token = authManager.accessToken else {
                print("No token available")
                return
            }

            Task {
                async let d: [Driver] = fetch("\(authManager.baseURL)get_api_data?data_needed=pindrivers", token: token)
                async let t: [Truck] = fetch("\(authManager.baseURL)get_api_data?data_needed=pintrucks", token: token)
                async let ig: [InGate] = fetch("\(authManager.baseURL)get_api_data?data_needed=piningates", token: token)
                async let og: [OutGate] = fetch("\(authManager.baseURL)get_api_data?data_needed=pinoutgates", token: token)
                async let pt: [PinTime] = fetch("\(authManager.baseURL)get_api_data?data_needed=pintimes", token: token)
                drivers = await (try? d) ?? []
                trucks = await (try? t) ?? []
                ingates = await (try? ig) ?? []
                outgates = await (try? og) ?? []
                pintimes = await (try? pt) ?? []
            }
        }

        // MARK: - Submit Data
        func submitAssignment() {
            guard let token = authManager.accessToken else { return }
            guard let driver = selectedDriver,
                  let truck = selectedTruck,
                  let ingate = selectedInGate,
                  let outgate = selectedOutGate,
                  let pintime = selectedPinTime else { return }
            
            let assignment: [String: String] = [
                "driver": driver.name,
                "truck": truck.unit,
                "ingate": ingate.unit,
                "outgate": outgate.unit,
                "pintime": pintime.name
            ]
            
            guard let url = URL(string: "\(authManager.baseURL)get_api_data?data_needed=pindata") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(assignment)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error:", error.localizedDescription)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        print("Unauthorized — maybe refresh token?")
                    } else if httpResponse.statusCode == 200 {
                        print("Assignment submitted successfully!")
                    } else {
                        print("Server response code: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        }

        // MARK: - Helper to Fetch Lists with Authorization
        func fetch<T: Decodable>(_ urlString: String, token: String) async throws -> T {
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("Unauthorized. Token may have expired.")
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    // MARK: - Models
    struct Driver: Identifiable, Codable, Hashable { let id: Int; let name: String }
    struct Truck: Identifiable, Codable, Hashable { let id: Int; let unit: String }
    struct InGate: Identifiable, Codable, Hashable { let id: Int; let unit: String }
    struct OutGate: Identifiable, Codable, Hashable { let id: Int; let unit: String }
    struct PinTime: Identifiable, Codable, Hashable { let id: Int; let name: String }
