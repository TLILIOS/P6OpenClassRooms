import XCTest
@testable import vitesse2

@MainActor
final class AddCandidateViewModelTests: XCTestCase {
    
    var viewModel: AddCandidateViewModel!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockNetworkService = MockNetworkService()
        // Configurez un token par défaut pour éviter les erreurs de token manquant
        await mockNetworkService.setToken("mockToken")
        viewModel = AddCandidateViewModel(networkService: mockNetworkService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    func testSaveCandidate_Success() async {
        // Arrange
        viewModel.firstName = "John"
        viewModel.lastName = "Doe"
        viewModel.email = "john.doe@example.com"
        viewModel.phone = "1234567890"
        
        let candidateResponse = Candidate(
            id: "123",
            firstName: viewModel.firstName,
            lastName: viewModel.lastName,
            email: viewModel.email,
            isFavorite: true
        )
        
        let candidateRequest = CandidateRequest(
            email: viewModel.email,
            note: nil,
            linkedinURL: nil,
            firstName: viewModel.firstName,
            lastName: viewModel.lastName,
            phone: viewModel.phone
        )
        
        guard let mockURL = Endpoint.createCandidate(candidateRequest).url else {
            XCTFail("URL non valide pour l'endpoint")
            return
        }
        
        mockNetworkService.mockResponses[mockURL] = .success(try! JSONEncoder().encode(candidateResponse))
        
        // Act
        let result = await viewModel.saveCandidate()
        
        // Assert
        XCTAssertTrue(result, "La sauvegarde du candidat aurait dû réussir")
        XCTAssertFalse(viewModel.showAlert, "Aucune alerte ne devrait être affichée en cas de succès")
        XCTAssertEqual(viewModel.errorMessage, "", "Le message d'erreur devrait être vide en cas de succès")
    }
    
    func testSaveCandidate_MissingFields() async {
        // Arrange
        viewModel.firstName = ""
        viewModel.lastName = "Doe"
        viewModel.email = "john.doe@example.com"
        
        // Act
        let result = await viewModel.saveCandidate()
        
        // Assert
        XCTAssertFalse(result, "La sauvegarde ne devrait pas réussir avec des champs manquants")
        XCTAssertTrue(viewModel.showAlert, "Une alerte devrait être affichée en cas de champs manquants")
        XCTAssertEqual(viewModel.errorMessage, "Veuillez remplir tous les champs requis")
        XCTAssertTrue(mockNetworkService.mockResponses.isEmpty, "Aucune requête réseau ne devrait être effectuée")
    }
    
    func testSaveCandidate_NetworkError() async {
        // Arrange
        viewModel.firstName = "John"
        viewModel.lastName = "Doe"
        viewModel.email = "john.doe@example.com"
        viewModel.phone = "1234567890"
        
        let candidateRequest = CandidateRequest(
            email: viewModel.email,
            note: nil,
            linkedinURL: nil,
            firstName: viewModel.firstName,
            lastName: viewModel.lastName,
            phone: viewModel.phone
        )
        
        guard let mockURL = Endpoint.createCandidate(candidateRequest).url else {
            XCTFail("URL non valide pour l'endpoint")
            return
        }
        
        mockNetworkService.mockResponses[mockURL] = .failure(NetworkService.NetworkError.serverError(500, "Erreur serveur"))
        
        // Act
        let result = await viewModel.saveCandidate()
        
        // Assert
        XCTAssertFalse(result, "La sauvegarde ne devrait pas réussir en cas d'erreur réseau")
        XCTAssertTrue(viewModel.showAlert, "Une alerte devrait être affichée en cas d'erreur réseau")
        XCTAssertEqual(viewModel.errorMessage, "Erreur serveur")
    }
}
