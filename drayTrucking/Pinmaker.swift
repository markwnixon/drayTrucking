//
//  Pinmaker.swift
//  drayTrucking
//
//  Created by Mark Nixon on 10/11/25.
//

import SwiftUI
import Foundation

struct PinAssignmentView: View {
    @State private var drivers: [Driver] = []
    @State private var trucks: [Truck] = []
    @State private var ingates: [InGate] = []
    @State private var outgates: [OutGate] = []
    @State private var pintimes: [PinTime] = []
    @State private var chassisNumber: String = ""

    
    @State private var selectedDriver: Driver?
    @State private var selectedTruck: Truck?
    @State private var selectedInGate: InGate?
    @State private var selectedOutGate: OutGate?
    @State private var selectedPinTime: PinTime?
    
    @State private var existingPins: [PinResponse] = []
    @State private var showExistingPins = false
    
    @State private var pindates: [PinDate] = []
    @State private var selectedPinDate: PinDate?
    
    @State private var pollingPinId: Int? = nil
    
    @AppStorage("scac") private var scac: String = ""
    @EnvironmentObject var authManager: AuthManager
    
    var isChassisEnabled: Bool {
        // Enable when:
        // - no ingate selected OR
        // - ingate.id == 0 (No In Gate)
        selectedInGate == nil || selectedInGate?.id == 0
    }

    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $showExistingPins) {
                    Text("Show Pins").tag(true)
                    Text("Create Assignment").tag(false)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if showExistingPins {
                    existingPinsView
                } else {
                    assignmentForm
                }
            }
            .navigationTitle("Pin Reservations")
            .onAppear {
                loadExistingPins()
                loadData()
                
                //Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                //    loadExistingPins()
                //}
            }
        }
    }
    func currentMinutes() -> Int {
        let now = Date()
        let cal = Foundation.Calendar(identifier: .gregorian) // fully qualify Calendar
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        return hour * 60 + minute
    }

    
    var existingPinsView: some View {
        let pinsToShow =
        pollingPinId == nil
        ? existingPins
        : existingPins.filter { $0.pinid == pollingPinId }
        
        return VStack {
            if pollingPinId != nil {
                VStack(spacing: 6) {
                    Text("Polling Active")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Fetching PIN information…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            List {
                if pinsToShow.isEmpty {
                    Text("No PIN assignments found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(pinsToShow.indices, id: \.self) { index in
                        let pin = pinsToShow[index]
                        let isPollingPin = pin.pinid == pollingPinId
                        
                        VStack(alignment: .leading, spacing: 6) {
                            
                            Text("PIN ID: \(String(pin.pinid))")
                                .font(.headline)
                            
                            if let intext = pin.intext, !intext.isEmpty {
                                Text("\(intext)")
                            }
                            
                            if let outtext = pin.outtext, !outtext.isEmpty {
                                Text("\(outtext)")
                            }
                            
                            if let note = pin.note, !note.isEmpty {
                                Text("Status: \(note)")
                                    .foregroundColor(.secondary)
                            }
                            // 🔥 Only show this if PIN is not yet obtained
                            if isPollingPin {
                                Button(role: .destructive) {
                                    abortPolling()
                                } label: {
                                    Label("Abort", systemImage: "xmark.circle.fill")
                                        .font(.body.bold())
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            else if pin.message == "NeedPin" {
                                HStack(spacing: 12) {
                                    Button {
                                        getActualPin(for: pin)
                                    } label: {
                                        Text("Get PIN")
                                            .font(.body.bold())
                                    }
                                    .buttonStyle(.borderedProminent)
                                    
                                    Spacer()

                                    Button(role: .destructive) {
                                        deletePin(pin)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }

                            else if pin.message == "InProgress" {
                                ProgressView()
                                    .padding(.top, 4)
                            }
                            
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }


            
            
    var assignmentForm: some View {
        Form {
            Section {
                Picker("Driver", selection: $selectedDriver) {
                    Text("Select a driver").tag(Optional<Driver>.none)
                    ForEach(drivers, id: \.id) { driver in
                        Text(driver.name).tag(Optional(driver))
                    }
                }
            }
            
            Section {
                Picker("Truck", selection: $selectedTruck) {
                    Text("Select a truck").tag(Optional<Truck>.none)
                    ForEach(trucks, id: \.id) { truck in
                        Text(truck.unit).tag(Optional(truck))
                    }
                }
            }
            
            Section {
                Picker("InGate", selection: $selectedInGate) {
                    Text("Select an InGate").tag(Optional<InGate>.none)
                    ForEach(ingates, id: \.id) { ingate in
                        Text(ingate.unit).tag(Optional(ingate))
                    }
                }
            }
            
            Section {
                Picker("OutGate", selection: $selectedOutGate) {
                    Text("Select an OutGate").tag(Optional<OutGate>.none)
                    ForEach(outgates, id: \.id) { outgate in
                        Text(outgate.unit).tag(Optional(outgate))
                    }
                }
            }
            
            Section {
                TextField("Chassis Number", text: $chassisNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .disabled(!isChassisEnabled)
                    .onChange(of: chassisNumber) {
                        chassisNumber = chassisNumber.uppercased()
                    }
            }

            
            Section {
                Picker("Date", selection: $selectedPinDate) {
                    Text("Select a Date").tag(Optional<PinDate>.none)
                    ForEach(pindates, id: \.id) { d in
                        Text(d.display).tag(Optional(d))
                    }
                }
            }
            
            Section {
                Picker("Time", selection: $selectedPinTime) {
                    Text("Select a Time").tag(Optional<PinTime>.none)
                    ForEach(pintimes, id: \.id) { pintime in
                        Text(pintime.name).tag(Optional(pintime))
                    }
                }
            }
            
            Button("Submit Assignment") {
                submitAssignment()
            }
            .disabled(
                selectedDriver == nil ||
                selectedTruck == nil ||
                selectedInGate == nil ||
                selectedOutGate == nil ||
                selectedPinDate == nil ||
                selectedPinTime == nil ||
                (selectedInGate?.id == 0 && chassisNumber.isEmpty)
            )
        }
    }
    
    func parseRange(from name: String) -> (Int, Int)? {
        let parts = name.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let start = minutesSinceMidnight(parts[0]),
              let end = minutesSinceMidnight(parts[1]) else { return nil }
        return (start, end)
    }
    
    func minutesSinceMidnight(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 60 + m
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
                async let pd: [PinDate] = fetch("\(authManager.baseURL)get_api_data?data_needed=pindates", token: token)
                async let pt: [PinTime] = fetch("\(authManager.baseURL)get_api_data?data_needed=pintimes", token: token)
                drivers = await (try? d) ?? []
                trucks = await (try? t) ?? []
                
                
                // ✅ Inject "No Gate" defaults
                let noInGate  = InGate(id: 0, unit: "No In Gate")
                let noOutGate = OutGate(id: 0, unit: "No Out Gate")
                let fetchedInGates  = await (try? ig) ?? []
                let fetchedOutGates = await (try? og) ?? []
                ingates  = [noInGate]  + fetchedInGates
                outgates = [noOutGate] + fetchedOutGates
                // ✅ Default selections (only once)
                if selectedInGate == nil {
                    selectedInGate = noInGate
                }
                if selectedOutGate == nil {
                    selectedOutGate = noOutGate
                }
                
                //ingates = await (try? ig) ?? []
                //outgates = await (try? og) ?? []
                
                pindates = await (try? pd) ?? []
                if selectedPinDate == nil {
                    selectedPinDate = pindates.first
                }
                pintimes = await (try? pt) ?? []
                let now = currentMinutes()
                if let match = pintimes.first(where: {
                    if let (start, end) = parseRange(from: $0.name) {
                        return now >= start && now < end
                    }
                    return false
                }) {
                    selectedPinTime = match
                }

            }
        }
            

    func loadExistingPins() {
        guard let token = authManager.accessToken else { return }
        guard let url = URL(string: "\(authManager.baseURL)get_existing_pins") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let pins = try? JSONDecoder().decode([PinResponse].self, from: data) {
                    DispatchQueue.main.async {
                        self.existingPins = pins
                        self.showExistingPins = !pins.isEmpty   // DEFAULT behavior
                    }
                }
            }
        }.resume()
    }
    
    func deletePin(_ pin: PinResponse) {
        guard let token = authManager.accessToken else { return }

        guard let url = URL(string: "\(authManager.baseURL)delete_pin?pinid=\(pin.pinid)") else {
            print("Invalid delete URL")
            return
        }

        var request = URLRequest(url: url)
        print(url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Delete error:", error.localizedDescription)
                return
            }

            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                DispatchQueue.main.async {
                    // Stop polling if this pin was being polled
                    if pollingPinId == pin.pinid {
                        pollingPinId = nil
                    }

                    existingPins.removeAll { $0.pinid == pin.pinid }
                }
            }
        }.resume()
    }

    
    // MARK: - Submit Data
    func submitAssignment() {
        guard let token = authManager.accessToken else { return }
        guard let driver = selectedDriver,
              let truck = selectedTruck,
              let ingate = selectedInGate,
              let outgate = selectedOutGate,
              let pindate = selectedPinDate,
              let pintime = selectedPinTime else { return }
          
        
        var assignment: [String: String] = [
            "driver": driver.name,
            "truck": truck.unit,
            "ingate": ingate.unit,
            "outgate": outgate.unit,
            "pindate": pindate.date,
            "pintime": pintime.name

        ]
        // ✅ Add chassis ONLY if present
        if !chassisNumber.isEmpty {
            assignment["chassis"] = chassisNumber
        }
    
        guard let url = URL(string: "\(authManager.baseURL)make_pin_data?data_needed=pindata") else { return }
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
                } else if httpResponse.statusCode == 200, let data = data {
                    if let decoded = try? JSONDecoder().decode(PinResponse.self, from: data) {
                        DispatchQueue.main.async {
                            self.existingPins.append(decoded)
                            self.showExistingPins = true
                        }
                    }
                    print("Assignment submitted successfully!")
                } else {
                    print("Server response code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    func pollForPinCompletion(
        pinId: Int,
        timeout: TimeInterval = 180,
        interval: TimeInterval = 5
    ) {
        guard let token = authManager.accessToken else { return }

        pollingPinId = pinId
        let startTime = Date()

        func poll() {
            // 🔴 Abort if user cancelled
            guard pollingPinId == pinId else {
                print("Polling aborted for PIN \(pinId)")
                return
            }

            guard let url = URL(
                string: "\(authManager.baseURL)pin_task_status?pinid=\(pinId)"
            ) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    print("Polling error:", error?.localizedDescription ?? "unknown")
                    return
                }

                guard let status = try? JSONDecoder().decode(PinTaskStatus.self, from: data) else {
                    print("Failed to decode pin task status")
                    return
                }

                DispatchQueue.main.async {
                    // 🔴 Abort again on main thread
                    guard self.pollingPinId == pinId else { return }

                    // 🔄 Update UI with live note
                    if let index = self.existingPins.firstIndex(where: { $0.pinid == pinId }) {
                        
                        self.existingPins[index].message = status.message
                        self.existingPins[index].note = status.note
                        
                        // ✅ Completed
                        if status.message != "NeedPin" {
                            //print("PIN \(pinId) completed:", status.message)
                            self.existingPins[index].intext = status.intext
                            self.existingPins[index].outtext = status.outtext
                            self.existingPins[index].note = status.note
                            self.pollingPinId = nil
                            return
                        }}

                    // ⏱ Timeout
                    if Date().timeIntervalSince(startTime) < timeout {
                        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                            poll()
                        }
                    } else {
                        print("Polling for PIN \(pinId) timed out")
                        self.pollingPinId = nil
                    }
                }
            }.resume()
        }

        poll()
    }


    
    
    func abortPolling() {
        print("Aborting polling for PIN \(pollingPinId ?? -1)")
        pollingPinId = nil
    }



    func getPinsFromAPI() {
        guard let token = authManager.accessToken else { return }

        guard let url = URL(string: "\(authManager.baseURL)get_pins") else { return }
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Get pins error:", error.localizedDescription)
                return
            }
            if let data = data {
                print("Pins received:", String(data: data, encoding: .utf8) ?? "Unknown format")
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
    
    func getActualPin(for pin: PinResponse) {
        guard let token = authManager.accessToken else {
            print("No access token available")
            return
        }

        guard let url = URL(string: "\(authManager.baseURL)get_pins_now?pinid=\(pin.pinid)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        print(url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request:", error.localizedDescription)
                return
            }

            // Check HTTP response code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response code:", httpResponse.statusCode)
                if httpResponse.statusCode != 200 {
                    print("Server returned error:", httpResponse.statusCode)
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("Response body:", body)
                    }
                    return
                }
            }

            // Optional: inspect raw data
            if let data = data {
                if let bodyString = String(data: data, encoding: .utf8) {
                    print("Raw response body:", bodyString)
                } else {
                    print("Received data, but could not decode as string")
                }
            }

            // Job queued successfully — now poll for completion
            DispatchQueue.main.async {
                pollingPinId = pin.pinid
                print(pin.pinid)
                self.pollForPinCompletion(pinId: pin.pinid)
            }

        }.resume()
    }




    
    
    
    
}

// MARK: - Models
struct Driver: Identifiable, Codable, Hashable { let id: Int; let name: String }
struct Truck: Identifiable, Codable, Hashable { let id: Int; let unit: String }
struct InGate: Identifiable, Codable, Hashable { let id: Int; let unit: String }
struct chassisNumber: Identifiable, Codable, Hashable { let id: Int; let unit: String }
struct OutGate: Identifiable, Codable, Hashable { let id: Int; let unit: String }
struct PinTime: Identifiable, Codable, Hashable { let id: Int; let name: String }

struct PinResponse: Codable, Hashable {
    var message: String
    var intext: String?
    var outtext: String?
    var note: String?
    let pinid: Int
}

struct PinTaskStatus: Decodable {
    let message: String
    let intext: String?
    let outtext: String?
    let note: String?
    let pinid: Int
}


struct TaskStartResponse: Codable {
    let task_id: String
    let status: String
}

struct PinDate: Codable, Identifiable, Hashable {
    let id: Int
    let date: String        // e.g. "2026-01-22"
    let display: String     // e.g. "Jan 22, 2026"
}





