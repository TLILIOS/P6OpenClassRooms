import Foundation
import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isRegistered: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
//    private let networkService = NetworkService.shared
    private let networkService: NetworkServiceProtocol

    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    // MARK: - Validation
    private var isValidInput: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        isValidEmail(email) &&
        isValidPassword()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword() -> Bool {
        password.count >= 6 && password == confirmPassword
    }
    
    // MARK: - Registration methods
    func register() async {
        guard isValidInput else {
            handleError(RegisterError.invalidInput)
            return
        }
        
        isLoading = true
        do {
            let _: EmptyResponse = try await networkService.request(.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            ))
            // Since registration was successful, we'll need to log in to get the token
            let authResponse: AuthResponse = try await networkService.request(.login(
                email: email,
                password: password
            ))
            TokenManager.shared.saveToken(authResponse.token)
            isRegistered = true
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else if let registerError = error as? RegisterError {
            errorMessage = registerError.message
        } else {
            errorMessage = "Une erreur inattendue s'est produite"
        }
        showAlert = true
        isLoading = false
    }
}

// MARK: - Custom Error
extension RegisterViewModel {
    enum RegisterError: Error {
        case invalidInput
        case passwordMismatch
        
        var message: String {
            switch self {
            case .invalidInput:
                return "Veuillez remplir tous les champs correctement"
            case .passwordMismatch:
                return "Les mots de passe ne correspondent pas"
            }
        }
    }
}
