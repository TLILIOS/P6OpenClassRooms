import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAdmin: Bool = false
    
    private let networkService = NetworkService.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if TokenManager.shared.getToken() != nil {
            // Token exists, verify it by making a test request
            Task {
                do {
                    let response: AuthResponse = try await networkService.request(.verifyToken)
                    isAuthenticated = true
                    isAdmin = response.isAdmin
                } catch {
                    // Token is invalid, clear it
                    TokenManager.shared.clearToken()
                    isAuthenticated = false
                    isAdmin = false
                }
            }
        } else {
            isAuthenticated = false
            isAdmin = false
        }
    }
    
    func logout() {
        TokenManager.shared.clearToken()
        isAuthenticated = false
        isAdmin = false
    }
}
