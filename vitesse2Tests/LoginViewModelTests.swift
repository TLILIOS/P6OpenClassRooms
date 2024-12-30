//
//  LoginViewModelTests
//  vitesse2Tests
//
//  Created by TLiLi Hamdi on 16/12/2024.
//

import XCTest
@testable import vitesse2

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var viewModel: LoginViewModel!
    private var mockNetworkService: MockNetworkService!
    private var mockTokenManager: MockTokenManager!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockTokenManager = MockTokenManager()
        viewModel = LoginViewModel(networkService: mockNetworkService, tokenManager: mockTokenManager)
    }

    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        mockTokenManager = nil
        super.tearDown()
    }
    

    func testHandleToken_success() async throws {
        // Arrange
        let token = "mockToken12345"
        let isAdmin = true

        // Act
        try await viewModel.testHandleToken(token, isAdmin: isAdmin)

        // Assert
        XCTAssertEqual(mockTokenManager.token, token, "Token should be saved in TokenManager")
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated")
        XCTAssertTrue(viewModel.isAdmin, "User should be an admin")
    }

    func testHandleToken_failure() async {
        // Arrange
        mockTokenManager.shouldFailToSaveToken = true
        let token = "mockToken12345"
        let isAdmin = false

        // Act & Assert
        do {
            try await viewModel.testHandleToken(token, isAdmin: isAdmin)
            XCTFail("Expected NetworkError.unauthorized, but no error was thrown")
        } catch let error as LoginViewModel.NetworkError {
            XCTAssertEqual(error, .unauthorized, "Expected unauthorized error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    func testLoginSuccess() async {
        // Arrange
        let mockResponse = AuthResponse(token: "mockToken12345", isAdmin: true)
        let mockData = try! JSONEncoder().encode(mockResponse)
        mockNetworkService.mockResponses[Endpoint.login(email: "test@example.com", password: "password123").url!] = .success(mockData)
        
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        // Act
        await viewModel.login()

        // Assert
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.isAdmin)
        XCTAssertEqual(mockTokenManager.token, "mockToken12345")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showAlert)
    }

    func testLoginInvalidInput() async {
        // Arrange
        viewModel.email = ""
        viewModel.password = ""

        // Act
        await viewModel.login()

        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Veuillez entrer un email et un mot de passe valides.")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginUnauthorized() async {
        // Arrange
        let mockError = NetworkService.NetworkError.unauthorized
        mockNetworkService.mockResponses[Endpoint.login(email: "test@example.com", password: "wrongPassword").url!] = .failure(mockError)
        
        viewModel.email = "test@example.com"
        viewModel.password = "wrongPassword"

        // Act
        await viewModel.login()

        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Non autorisé")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginServerError() async {
        // Arrange
        let mockError = NetworkService.NetworkError.serverError(500, "Erreur serveur: 500")
        mockNetworkService.mockResponses[Endpoint.login(email: "test@example.com", password: "password123").url!] = .failure(mockError)
        
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        // Act
        await viewModel.login()

        // Assert
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Erreur serveur: 500")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    func testHandleError_withLoginNetworkError() {
        // Arrange
        let error = LoginViewModel.NetworkError.invalidInput

        // Act
        viewModel.testHandleError(error)

        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Veuillez entrer un email et un mot de passe valides.")
        XCTAssertTrue(viewModel.showAlert, "Alert should be shown")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after handling error")
    }

    final class NetworkErrorTests: XCTestCase {
        
        func testNetworkErrorMessages() {
            // Arrange & Act & Assert
            
            // Test invalidInput
            let invalidInputError = LoginViewModel.NetworkError.invalidInput
            XCTAssertEqual(invalidInputError.message, "Veuillez entrer un email et un mot de passe valides.",
                           "Message for invalidInput should match")

            // Test unauthorized
            let unauthorizedError = LoginViewModel.NetworkError.unauthorized
            XCTAssertEqual(unauthorizedError.message, "Authentification échouée. Veuillez réessayer.",
                           "Message for unauthorized should match")
        }
        
        func testNetworkErrorEquality() {
            // Arrange
            let error1 = LoginViewModel.NetworkError.invalidInput
            let error2 = LoginViewModel.NetworkError.invalidInput
            
            // Assert
            XCTAssertEqual(error1, error2, "The same NetworkError cases should be equal")
        }
        
        func testNetworkErrorDifferentCases() {
            // Arrange
            let error1 = LoginViewModel.NetworkError.invalidInput
            let error2 = LoginViewModel.NetworkError.unauthorized
            
            // Assert
            XCTAssertNotEqual(error1, error2, "Different NetworkError cases should not be equal")
        }
    }
    func testHandleError_withNetworkServiceError() {
        // Arrange
        let error = NetworkService.NetworkError.unauthorized

        // Act
        viewModel.testHandleError(error)

        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Non autorisé")
        XCTAssertTrue(viewModel.showAlert, "Alert should be shown")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after handling error")
    }

    func testHandleError_withUnknownError() {
        // Arrange
        let error = NSError(domain: "Unknown", code: 0, userInfo: nil)

        // Act
        viewModel.testHandleError(error)

        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Une erreur inattendue s'est produite")
        XCTAssertTrue(viewModel.showAlert, "Alert should be shown")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after handling error")
    }
}


extension LoginViewModel {
    func testHandleToken(_ token: String, isAdmin: Bool) async throws {
        try await self.handleToken(token, isAdmin: isAdmin)
    }
}
