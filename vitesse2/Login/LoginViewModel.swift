import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    private let networkService: NetworkServiceProtocol
    private let tokenManager: TokenManagerProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.networkService = networkService
        self.tokenManager = tokenManager
    }

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isAdmin: Bool = false
    @Published var isLoading: Bool = false

    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && LoginViewModel.isValidEmail(email)
    }

    func login() async {
        guard isValidInput else {
            handleError(LoginViewModel.NetworkError.invalidInput)
            return
        }

        isLoading = true
        do {
            let response: AuthResponse = try await networkService.request(.login(email: email, password: password))
            try await handleToken(response.token, isAdmin: response.isAdmin)
        } catch {
            handleError(error)
        }
        isLoading = false
    }

    internal func handleToken(_ token: String, isAdmin: Bool) async throws {
        tokenManager.saveToken(token) // Ajout pour sauvegarder le token dans le MockTokenManager
        if let storedToken = tokenManager.getToken() {
            print("Token successfully stored: \(String(storedToken.prefix(10)))...")
            isAuthenticated = true
            self.isAdmin = isAdmin
        } else {
            print("Failed to store token")
            throw NetworkError.unauthorized
        }
    }

    private func handleError(_ error: Error) {
        if let networkError = error as? LoginViewModel.NetworkError {
            errorMessage = networkError.message
        } else if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else {
            errorMessage = "Une erreur inattendue s'est produite"
        }

        showAlert = true
        isLoading = false
    }

    enum NetworkError: Error {
        case invalidInput
        case unauthorized

        var message: String {
            switch self {
            case .invalidInput:
                return "Veuillez entrer un email et un mot de passe valides."
            case .unauthorized:
                return "Authentification échouée. Veuillez réessayer."
            }
        }
    }
}
extension LoginViewModel {
    func testHandleError(_ error: Error) {
        handleError(error)
    }
}
