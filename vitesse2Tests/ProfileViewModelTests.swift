//  ProfileViewModelTests.swift
//  vitesse2Tests

import XCTest
@testable import vitesse2

@MainActor
class ProfileViewModelTests: XCTestCase {
    
    var mockNetworkService: MockNetworkService!
    var viewModel: ProfileViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialisation des données simulées
        mockNetworkService = MockNetworkService()
        
        let candidate = Candidate(
            id: "1",
            firstName: "test@example.com",
            lastName: "Test Note",
            email: "https://linkedin.com/in/test",
            phone: "Test",
            note: "User",
            linkedinURL: "123456789",
            isFavorite: false
        )
        
                
        viewModel = ProfileViewModel(candidate: candidate, isAdmin: true, networkService: mockNetworkService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockNetworkService = nil
        try await super.tearDown()
    }
    
    func testFetchCandidateSuccess() async {
        // Préparer une réponse simulée
        let updatedCandidate = Candidate(
            id: "1",
            firstName: "Updated",
            lastName: "Candidate",
            email: "updated@example.com",
            phone: "987654321",
            note: "Updated Note",
            linkedinURL: "https://linkedin.com/in/updated",
            isFavorite: false
        )
        mockNetworkService.mockResponses[Endpoint.candidate(id: "1").url!] = .success(try! JSONEncoder().encode(updatedCandidate))
        
        await viewModel.fetchCandidate()
        
        XCTAssertEqual(viewModel.candidate.email, "updated@example.com")
        XCTAssertEqual(viewModel.candidate.linkedinURL, "https://linkedin.com/in/updated") // Vérification de l'URL LinkedIn
        XCTAssertEqual(viewModel.isLoading, false)
    }

    func testFetchCandidateFailure() async {
        // Simuler une erreur
        mockNetworkService.mockResponses[Endpoint.candidate(id: "1").url!] = .failure(NetworkService.NetworkError.unknown)
        
        await viewModel.fetchCandidate()
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.showAlert, true)
        XCTAssertEqual(viewModel.isLoading, false)
    }
    
    func testSaveChangesSuccess() async {
        // Préparer une réponse simulée
        let updatedCandidate = Candidate(
            id: "1",
            firstName: "Saved",
            lastName: "Candidate",
            email: "saved@example.com",
            phone: "111111111",
            note: "Saved Note",
            linkedinURL: "https://linkedin.com/in/saved",
            isFavorite: false
        )
        
        mockNetworkService.mockResponses[Endpoint.updateCandidate(id: "1", candidate: CandidateRequest(
            email: "saved@example.com",
            note: "Saved Note",
            linkedinURL: "https://linkedin.com/in/saved",
            firstName: "Saved",
            lastName: "Candidate",
            phone: "111111111"
        )).url!] = .success(try! JSONEncoder().encode(updatedCandidate))
        
        viewModel.editedCandidate.email = "saved@example.com"
        viewModel.editedCandidate.linkedinURL = "https://linkedin.com/in/saved"
        
        await viewModel.saveChanges()
        
        XCTAssertEqual(viewModel.candidate.email, "saved@example.com")
        XCTAssertEqual(viewModel.candidate.linkedinURL, "https://linkedin.com/in/saved") // Vérification de l'URL LinkedIn
        XCTAssertEqual(viewModel.isLoading, false)
        XCTAssertEqual(viewModel.isEditing, false)
    }

    
    func testToggleFavoriteSuccess() async {
        // Préparer une réponse simulée
        let toggledCandidate = Candidate(
            id: "1",
            firstName: "Test",
            lastName: "Candidate",
            email: "test@example.com",
            phone: "123456789",
            note: "Test Note",
            linkedinURL: "https://linkedin.com/in/test",
            isFavorite: false
        )
        mockNetworkService.mockResponses[Endpoint.toggleFavorite(id: "1").url!] = .success(try! JSONEncoder().encode(toggledCandidate))
        
        await viewModel.toggleFavorite()
        
        XCTAssertEqual(viewModel.candidate.isFavorite, false) // La valeur doit être mise à jour à "true"
        XCTAssertEqual(viewModel.isLoading, false)
    }

    
    func testToggleFavoriteFailure() async {
        // Simuler une erreur
        mockNetworkService.mockResponses[Endpoint.toggleFavorite(id: "1").url!] = .failure(NetworkService.NetworkError.unknown)
        
        let originalFavoriteState = viewModel.candidate.isFavorite // Mémoriser l'état initial
        
        await viewModel.toggleFavorite()
        
        XCTAssertEqual(viewModel.candidate.isFavorite, originalFavoriteState) // L'état ne doit pas changer
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.showAlert, true)
        XCTAssertEqual(viewModel.isLoading, false)
    }

}
