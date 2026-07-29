import SwiftUI
import Security

// MARK: - Main View
struct LoginView: View {
    //@State private var username: String = ""
    @State private var password: String = ""
    @State private var loginFailed = false
    
 //   @AppStorage("isLoggedIn") private var isLoggedIn = false
 //   @State private var message: String = ""
    
  //  @State private var isLoading = false
   // @State private var errorMessage: ErrorMessage?
    
    @AppStorage("username") private var username: String = ""
    //@AppStorage("password") private var password: String = ""
    @AppStorage("scac") private var scac: String = ""
    @AppStorage("baseURL") private var baseURL: String = ""
    
    //private let service = "com.example.myapp"
    //@AppStorage("lastUsername") private var lastUsername: String = ""
   // @AppStorage("lastScac") private var lastScac: String = ""
    
    //@StateObject private var authManager = AuthManager()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    
    var body: some View {
        VStack(spacing: 25) {
            //Text("inside loginview we have auth set as \(authManager.isAuthenticated)")
            if authManager.isAuthenticated {
                VStack {
                    Text("Welcome, \(username)! 🎉")
                        .font(.title)
                        .bold()
                    
                    Text("Your SCAC Code is: \(scac)")
                        .font(.title)
                        .bold()
                    
                    
                    Button("Log Out") {
                        authManager.logout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                //Text("From Loginview1 going to Contentview with authmanager: \(authManager.isAuthenticated)")
                
                ContentView()
                
            } else {
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image("draylogo2")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: horizontalSizeClass == .regular ? 280 : 190)
                    
                    Text("🔐 Secure Login")
                        .font(.largeTitle)
                        .bold()
                    
                    
                    TextField("SCAC Code", text: Binding(
                        get: { scac },
                        set: { scac = $0.uppercased() }
                    ))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                    TextField("Username", text: $username)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if authManager.loginFailed {
                        Text("Invalid username or password.")
                            .foregroundColor(.red)
                    }
                    
                    // Login Button
                    //let baseURL = scacList.contains(scac) ? urls[scac] : ""
                    let baseURL = scacList.contains(scac) ? (urls[scac] ?? "") : ""
                    let buttontext = scacList.contains(scac) ? "Log In" : "SCAC Invalid"
                        Button(buttontext) {
                            authManager.login(username: username, password: password, scac: scac, baseURL: baseURL)  //ensures scac and baseURL available and updated for login first call
                            authManager.scac = scac //needed to update scac in class
                            authManager.baseURL = baseURL //needed to update baseURL in class
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(!scacList.contains(scac))
            
                    }
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 24)
                    .padding(.vertical, horizontalSizeClass == .regular ? 60 : 24)
                    .frame(maxWidth: .infinity)
                }

            }
            }
        }
    }
