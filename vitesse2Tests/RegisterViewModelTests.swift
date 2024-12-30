import XCTest
@testable import vitesse2

@MainActor
final class RegisterViewModelTests: XCTestCase {
    var sut: RegisterViewModel!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = RegisterViewModel(networkService: mockNetworkService)
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    // MARK: - Validation Tests
    func testValidRegistrationData() async {
        // Given
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "john.doe@example.com"
        sut.password = "password123"
        sut.confirmPassword = "password123"
        
        // When
        let registerEndpoint = Endpoint.register(
            email: sut.email,
            password: sut.password,
            firstName: sut.firstName,
            lastName: sut.lastName
        )
        
        let registerData = try! JSONEncoder().encode(EmptyResponse())
        let loginData = try! JSONEncoder().encode(AuthResponse(token: "fake-token", isAdmin: false))
        
        mockNetworkService.mockResponses[registerEndpoint.url!] = .success(registerData)
        mockNetworkService.mockResponses[Endpoint.login(email: sut.email, password: sut.password).url!] = .success(loginData)
        
        // Then
        await sut.register()
        XCTAssertTrue(sut.isRegistered)
        XCTAssertFalse(sut.showAlert)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testRegistrationWithInvalidEmail() async {
        // Given
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "invalid-email"
        sut.password = "password123"
        sut.confirmPassword = "password123"
        
        // When
        await sut.register()
        
        // Then
        XCTAssertFalse(sut.isRegistered)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs correctement")
    }
    
    func testRegistrationWithPasswordMismatch() async {
        // Given
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "john.doe@example.com"
        sut.password = "password123"
        sut.confirmPassword = "different"
        
        // When
        await sut.register()
        
        // Then
        XCTAssertFalse(sut.isRegistered)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs correctement")
    }
    
    func testRegistrationWithNetworkError() async {
        // Given
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "john.doe@example.com"
        sut.password = "password123"
        sut.confirmPassword = "password123"
        
        let registerEndpoint = Endpoint.register(
            email: sut.email,
            password: sut.password,
            firstName: sut.firstName,
            lastName: sut.lastName
        )
        
        mockNetworkService.mockResponses[registerEndpoint.url!] = .failure(NetworkService.NetworkError.serverError(500, "Erreur serveur"))
        
        // When
        await sut.register()
        
        // Then
        XCTAssertFalse(sut.isRegistered)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Erreur serveur")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testRegistrationWithEmptyFields() async {
        // Given
        sut.firstName = ""
        sut.lastName = ""
        sut.email = ""
        sut.password = ""
        sut.confirmPassword = ""
        
        // When
        await sut.register()
        
        // Then
        XCTAssertFalse(sut.isRegistered)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs correctement")
    }
}
