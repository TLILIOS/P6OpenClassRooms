import XCTest
@testable import vitesse2

@MainActor
final class AddCandidateViewModelTests: XCTestCase {
    var sut: AddCandidateViewModel!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockNetworkService = MockNetworkService()
        await mockNetworkService.setToken("mock-token") // Ajouter un token mock
        sut = AddCandidateViewModel(networkService: mockNetworkService)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockNetworkService = nil
        try await super.tearDown()
    }
    
    // MARK: - SaveCandidate Tests - Validation
    
    func testSaveCandidate_WithEmptyFirstName_ReturnsFalse() async {
        // Arrange
        sut.lastName = "Doe"
        sut.email = "john.doe@test.com"
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs requis")
        XCTAssertTrue(sut.showAlert)
    }
    
    func testSaveCandidate_WithEmptyLastName_ReturnsFalse() async {
        // Arrange
        sut.firstName = "John"
        sut.email = "john.doe@test.com"
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs requis")
        XCTAssertTrue(sut.showAlert)
    }
    
    func testSaveCandidate_WithEmptyEmail_ReturnsFalse() async {
        // Arrange
        sut.firstName = "John"
        sut.lastName = "Doe"
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs requis")
        XCTAssertTrue(sut.showAlert)
    }
    
    func testSaveCandidate_WithInvalidEmail_ReturnsFalse() async {
        // Arrange
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "invalid.email"
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Veuillez remplir tous les champs requis")
        XCTAssertTrue(sut.showAlert)
    }
    
    // MARK: - SaveCandidate Tests - Network
    
    func testSaveCandidate_Success() async throws {
        // Arrange
        setupValidCandidate()
        let expectedCandidate = Candidate(id: "1", 
                                        firstName: sut.firstName,
                                        lastName: sut.lastName,
                                        email: sut.email,
                                        phone: sut.phone,
                                        note: sut.note,
                                        linkedinURL: sut.linkedinURL,
                                        isFavorite: false)
        
        // Créer la requête pour obtenir l'URL correcte
        let request = createCandidateRequest()
        let endpoint = Endpoint.createCandidate(request)
        guard let url = endpoint.url else {
            XCTFail("URL invalide")
            return
        }
        
        mockNetworkService.mockResponses = .success(try JSONEncoder().encode(expectedCandidate))
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(sut.showAlert)
        XCTAssertTrue(sut.errorMessage.isEmpty)
    }
    
    func testSaveCandidate_WithServerError() async {
        // Arrange
        setupValidCandidate()
        mockNetworkService.mockError = NetworkService.NetworkError.serverError(500, "Erreur serveur")
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Erreur serveur")
    }
    
    func testSaveCandidate_WithMissingToken() async {
        // Arrange
        setupValidCandidate()
        mockNetworkService.token = nil // Supprimer directement le token
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Token d'authentification manquant")
    }
    
    func testSaveCandidate_WithUnexpectedError() async {
        // Arrange
        setupValidCandidate()
        struct CustomError: Error {}
        mockNetworkService.mockError = CustomError()
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Une erreur inattendue s'est produite")
    }
    
    // MARK: - SaveCandidate Tests - Optional Fields
    
    func testSaveCandidate_WithOptionalFieldsEmpty_Success() async throws {
        // Arrange
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "john.doe@test.com"
        // Laisser les champs optionnels vides
        
        let expectedCandidate = Candidate(id: "1",
                                        firstName: sut.firstName,
                                        lastName: sut.lastName,
                                        email: sut.email,
                                        phone: nil,
                                        note: nil,
                                        linkedinURL: nil,
                                        isFavorite: false)
        
        // Créer la requête pour obtenir l'URL correcte
//        let request = createCandidateRequest()
//        let endpoint = Endpoint.createCandidate(request)
//        guard let url = endpoint.url else {
//            XCTFail("URL invalide")
//            return
//        }
        
        mockNetworkService.mockResponses = .success(try JSONEncoder().encode(expectedCandidate))
        
        // Act
        let result = await sut.saveCandidate()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(sut.showAlert)
        XCTAssertTrue(sut.errorMessage.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func setupValidCandidate() {
        sut.firstName = "John"
        sut.lastName = "Doe"
        sut.email = "john.doe@test.com"
        sut.phone = "123456789"
        sut.linkedinURL = "linkedin.com/johndoe"
        sut.note = "Note test"
    }
    
    private func createCandidateRequest() -> CandidateRequest {
        CandidateRequest(
            email: sut.email,
            note: sut.note.isEmpty ? nil : sut.note,
            linkedinURL: sut.linkedinURL.isEmpty ? nil : sut.linkedinURL,
            firstName: sut.firstName,
            lastName: sut.lastName,
            phone: sut.phone.isEmpty ? nil : sut.phone
        )
    }
}
