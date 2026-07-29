//
//  AuthManager.swift
//  drayTrucking
//
//  Created by Mark Nixon on 9/28/25.
//
import Foundation
import Combine
import Security

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var loginFailed = false
    @Published var scac: String = ""
    @Published var baseURL: String = ""
    
    private let scacKey = "userSCAC"
    private let baseURLKey = "userBaseURL"

    //@Published var baseURL: String? = nil

    //private let baseURL = "http://127.0.0.1:5000/"
    //private let baseURL = urls[scac]
    
    @Published var accessToken: String? {
        didSet { isAuthenticated = accessToken != nil }
    }
    
    private var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                KeychainHelper.save(Data(token.utf8),
                                    service: "MyAppAuth",
                                    account: "refreshToken")
            } else {
                KeychainHelper.delete(service: "MyAppAuth", account: "refreshToken")
            }
        }
    }
    
    init() {
        self.scac = UserDefaults.standard.string(forKey: scacKey) ?? ""
        self.baseURL = UserDefaults.standard.string(forKey: baseURLKey) ?? ""
        
        // Load refresh token from Keychain at startup
        if let data = KeychainHelper.read(service: "MyAppAuth", account: "refreshToken"),
           let token = String(data: data, encoding: .utf8) {
            self.refreshToken = token
            // Try to get a new access token using refresh
                    self.refreshAccessToken { success in
                        DispatchQueue.main.async {
                            self.isAuthenticated = success
                        }
                    }
            
            // Try refreshing access token immediately
            //refreshAccessToken { _ in }
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String, scac: String, baseURL: String) {
        self.scac = scac
        self.baseURL = baseURL
        
        UserDefaults.standard.set(scac, forKey: scacKey)
        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
        
        guard let url = URL(string: "\(baseURL)api_login") else { return }
        print("The login url is \(url) and baseURL: \(baseURL) and scac: \(scac)")
        let body = ["username": username, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
            
                guard let httpResponse = response as? HTTPURLResponse  else {
                    self.isAuthenticated = false
                    self.loginFailed = true
                    return
                }
                
                if httpResponse.statusCode == 200,
                   let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let access = json["access_token"] as? String,
                   let refresh = json["refresh_token"] as? String {
                    
                    // ✅ only now mark login successful
                    self.accessToken = access
                    self.refreshToken = refresh
                    self.isAuthenticated = true
                    self.loginFailed = false
                    
                } else if httpResponse.statusCode == 401 {
                                // ❌ Unauthorized, try refresh if we have a refresh token
                    if self.refreshToken != nil {
                                    self.refreshAccessToken { success in
                                        if success {
                                            // Retry login automatically
                                            print("Retry of login automatically")
                                            self.login(username: username, password: password, scac:scac, baseURL: baseURL)
                                        } else {
                                            self.isAuthenticated = false
                                            self.loginFailed = true
                                        }
                                    }
                                } else {
                                    self.isAuthenticated = false
                                    self.loginFailed = true
                                }

                            } else {
                                self.isAuthenticated = false
                                self.loginFailed = true
                            }
                        }
                    }.resume()
                }
    
    // MARK: - Refresh Access Token
    private func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)refresh"),
              let refresh = refreshToken else {
            completion(false)
            return
        }
        print("Refreshing acccess token: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(refresh)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newAccess = json["access_token"] as? String else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                self?.accessToken = newAccess
                completion(true)
            }
        }.resume()
    }
    
    // MARK: - Logout
    func logout() {
        print("Logging Out per request")
        accessToken = nil
        refreshToken = nil // deletes from Keychain
        isAuthenticated = false
        loginFailed = false
        UserDefaults.standard.removeObject(forKey: scacKey)
        UserDefaults.standard.removeObject(forKey: baseURLKey)
    }
    
    // MARK: - Fetch Protected Data
    func fetchAPI<T: Decodable>(url: String, completion: @escaping (T) -> Void) {
        
        guard let apiUrl = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            return
        }
        guard let token = accessToken else {
            print("❌ Missing access token")
            return
        }
        
        let decoder = JSONDecoder()
        //decoder.dateDecodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }())
        
        print("Fetching data with url \(apiUrl)")
        // Set up the request for a protected request
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP status: \(httpResponse.statusCode)")
                
                // If unauthorized, refresh token and retry
                if httpResponse.statusCode == 401 {
                    self?.refreshAccessToken { success in
                        if success {
                            // Retry the original call after refreshing
                            self?.fetchAPI(url: url, completion: completion)
                        } else {
                            print("❌ Failed to refresh token")
                        }
                    }
                    return
                }
            }
            
            // Ensure we have data
            guard let data = data else {
                print("❌ No data received from API")
                return
            }
            
            // 🧾 Print raw response (for debugging)
            //       if let rawResponse = String(data: data, encoding: .utf8) {
            //           print("📦 Raw API response:\n\(rawResponse)")
            //       }
            
            //guard let data = data, error == nil else { return }
            
            if let decodedData = try? decoder.decode(T.self, from: data)
            {
                DispatchQueue.main.async {
                    completion(decodedData)
                }
            }
        }.resume()
    }

    
}

struct KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Remove old value
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
    
    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
    

}
