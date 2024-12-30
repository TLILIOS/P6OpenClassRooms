import XCTest
@testable import vitesse2

@MainActor
final class CandidateListViewModelTests: XCTestCase {
    // MARK: - Properties
    private var sut: CandidateListViewModel!
    private var mockNetworkService: MockNetworkService!
    
    // MARK: - Test Data
    private let defaultCandidate = Candidate(
        id: "1",
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        phone: "123456789",
        isFavorite: false
    )
    
    private let mockCandidates = [
        Candidate(id: "1", firstName: "John", lastName: "Doe",
                 email: "john@example.com", phone: "123456789", isFavorite: false),
        Candidate(id: "2", firstName: "Jane", lastName: "Smith",
                 email: "jane@example.com", phone: "987654321", isFavorite: true),
        Candidate(id: "3", firstName: "Alice", lastName: "Johnson",
                 email: "alice@example.com", phone: "456789123", isFavorite: false)
    ]
    // MARK: - Toggle Favorite Sync Tests
    func testToggleFavoriteSyncAsAdmin() async throws {
        // Given
        let candidate = mockCandidates[0]
        sut.candidates = [candidate]
        
        let updatedCandidate = Candidate(
            id: candidate.id,
            firstName: candidate.firstName,
            lastName: candidate.lastName,
            email: candidate.email,
            phone: candidate.phone,
            isFavorite: true
        )
        
        try setupMockResponse(for: .toggleFavorite(id: candidate.id), with: updatedCandidate)
        
        // When
        sut.toggleFavoriteSync(for: candidate)
        try await waitForAsyncOperation()
        
        // Then
        XCTAssertTrue(sut.candidates.first?.isFavorite ?? false, "The candidate's favorite status should be updated to true")
    }

    func testToggleFavoriteSyncAsNonAdmin() async {
        // Given
        sut = CandidateListViewModel(networkService: mockNetworkService, isAdmin: false, shouldFetchOnInit: false)
        let candidate = mockCandidates[0]
        sut.candidates = [candidate]
        
        // When
        sut.toggleFavoriteSync(for: candidate)
        try? await waitForAsyncOperation()
        
        // Then
        XCTAssertFalse(sut.candidates.first?.isFavorite ?? true, "The candidate's favorite status should remain unchanged for non-admin")
        XCTAssertFalse(sut.isLoading, "Loading state should not be triggered for non-admin")
    }

    // MARK: - Lifecycle
    override func setUp() async throws {
        try await super.setUp()
        mockNetworkService = MockNetworkService()
        await mockNetworkService.setToken("fake-token")
        sut = CandidateListViewModel(networkService: mockNetworkService, isAdmin: true, shouldFetchOnInit: false)
    }
    
    override func tearDown() {
        mockNetworkService.mockResponses.removeAll()
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func setupMockResponse<T: Encodable>(for endpoint: Endpoint, with data: T) throws {
        let encodedData = try JSONEncoder().encode(data)
        mockNetworkService.mockResponses[endpoint.url!] = .success(encodedData)
    }
    
    private func setupMockError(for endpoint: Endpoint, code: Int = 500, message: String = "Erreur serveur") {
        mockNetworkService.mockResponses[endpoint.url!] = .failure(
            NetworkService.NetworkError.serverError(code, message)
        )
    }
    
    private func waitForAsyncOperation() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    // MARK: - Initialization Tests
    func testInitialization() {
        XCTAssertTrue(sut.candidates.isEmpty, "La liste devrait être vide")
        XCTAssertTrue(sut.isAdmin, "Devrait être admin")
        XCTAssertFalse(sut.isLoading, "Ne devrait pas être en chargement")
        XCTAssertFalse(sut.showAlert, "Ne devrait pas afficher d'alerte")
        XCTAssertTrue(sut.selectedCandidates.isEmpty, "Aucune sélection")
        XCTAssertFalse(sut.showOnlyFavorites, "Ne devrait pas filtrer les favoris")
    }
    
    // MARK: - Fetch Tests
    func testFetchCandidatesSuccess() async throws {
        // Given
        try setupMockResponse(for: .candidates, with: mockCandidates)
        
        // When
        await sut.fetchCandidates()
        
        // Then
        XCTAssertEqual(sut.candidates.count, mockCandidates.count)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showAlert)
    }
    
    // MARK: - Filter Tests
    func testFilterBySearchText() {
        // Given
        sut.candidates = mockCandidates
        
        // When
        sut.searchText = "john"
        
        // Then
        XCTAssertEqual(sut.filteredCandidates.count, 2) // John Doe and Jane Smith match
        XCTAssertTrue(sut.filteredCandidates.contains { $0.firstName.lowercased() == "john" })
        XCTAssertTrue(sut.filteredCandidates.contains { $0.email.contains("john") })
    }

    
    func testFilterByEmail() {
        // Given
        sut.candidates = mockCandidates
        
        // When
        sut.searchText = "@example"
        
        // Then
        XCTAssertEqual(sut.filteredCandidates.count, 3)
        XCTAssertTrue(sut.filteredCandidates.allSatisfy { $0.email.contains("@example") })
    }
    
    func testFilterByFavorites() {
        // Given
        sut.candidates = mockCandidates
        
        // When
        sut.showOnlyFavorites = true
        
        // Then
        XCTAssertEqual(sut.filteredCandidates.count, 1)
        XCTAssertEqual(sut.filteredCandidates.first?.firstName, "Jane")
    }
    
    // MARK: - Selection Tests
    func testToggleSelection() {
        // Given
        let candidate = mockCandidates[0]
        
        // When - Select
        sut.toggleSelection(for: candidate)
        
        // Then
        XCTAssertTrue(sut.selectedCandidates.contains(candidate.id))
        
        // When - Deselect
        sut.toggleSelection(for: candidate)
        
        // Then
        XCTAssertFalse(sut.selectedCandidates.contains(candidate.id))
    }
    
    // MARK: - Delete Tests
    func testDeleteCandidateSuccess() async throws {
        // Given
        sut.candidates = mockCandidates
        let candidateToDelete = mockCandidates[0]
        mockNetworkService.mockResponses[Endpoint.deleteCandidate(id: candidateToDelete.id).url!] = .success(Data())
        
        let updatedCandidates = Array(mockCandidates.dropFirst())
        try setupMockResponse(for: .candidates, with: updatedCandidates)
        
        // When
        await sut.deleteCandidate(candidateToDelete)
        
        // Then
        XCTAssertEqual(sut.candidates.count, 2)
        XCTAssertFalse(sut.candidates.contains { $0.id == candidateToDelete.id })
    }
    
    // MARK: - Favorite Tests
    func testToggleFavoriteAsAdmin() async throws {
        // Given
        let candidate = mockCandidates[0]
        sut.candidates = [candidate]
        
        let updatedCandidate = Candidate(
            id: candidate.id,
            firstName: candidate.firstName,
            lastName: candidate.lastName,
            email: candidate.email,
            phone: candidate.phone,
            isFavorite: true
        )
        
        try setupMockResponse(for: .toggleFavorite(id: candidate.id), with: updatedCandidate)
        
        // When
        await sut.toggleFavorite(for: candidate)
        
        // Then
        XCTAssertTrue(sut.candidates.first?.isFavorite ?? false)
    }
    
    func testToggleFavoriteAsNonAdmin() async {
        // Given
        sut = CandidateListViewModel(networkService: mockNetworkService, isAdmin: false, shouldFetchOnInit: false)
        let candidate = mockCandidates[0]
        sut.candidates = [candidate]
        
        // When
        await sut.toggleFavorite(for: candidate)
        
        // Then
        XCTAssertFalse(sut.candidates.first?.isFavorite ?? true)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Error Handling Tests
    func testHandleNetworkError() {
        // Given
        let networkError = NetworkService.NetworkError.serverError(500, "Erreur serveur")
        
        // When
        sut.testHandleError(networkError)
        
        // Then
        XCTAssertEqual(sut.errorMessage, "Erreur serveur")
        XCTAssertTrue(sut.showAlert)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Delete Selected Candidates Tests
    func testDeleteSelectedCandidatesSuccess() async throws {
        // Given
        sut.candidates = mockCandidates
        sut.selectedCandidates = Set(["1", "2"]) // Selecting John and Jane

        for candidateId in sut.selectedCandidates {
            mockNetworkService.mockResponses[Endpoint.deleteCandidate(id: candidateId).url!] = .success(Data())
        }
        
        let updatedCandidates = mockCandidates.filter { $0.id != "1" && $0.id != "2" }
        try setupMockResponse(for: .candidates, with: updatedCandidates)

        // When
        await sut.deleteSelectedCandidates()
        
        // Then
        XCTAssertEqual(sut.candidates.count, 1)
        XCTAssertTrue(sut.candidates.contains { $0.id == "3" })
        XCTAssertFalse(sut.candidates.contains { $0.id == "1" || $0.id == "2" })
        XCTAssertTrue(sut.selectedCandidates.isEmpty)
        XCTAssertFalse(sut.isEditing)
    }

    func testDeleteSelectedCandidatesSyncSuccess() async throws {
        // Given
        sut.candidates = mockCandidates
        sut.selectedCandidates = Set(["1", "2"]) // Selecting John and Jane

        for candidateId in sut.selectedCandidates {
            mockNetworkService.mockResponses[Endpoint.deleteCandidate(id: candidateId).url!] = .success(Data())
        }
        
        let updatedCandidates = mockCandidates.filter { $0.id != "1" && $0.id != "2" }
        try setupMockResponse(for: .candidates, with: updatedCandidates)

        // When
        sut.deleteSelectedCandidatesSync()
        try await waitForAsyncOperation()
        
        // Then
        XCTAssertEqual(sut.candidates.count, 1)
        XCTAssertTrue(sut.candidates.contains { $0.id == "3" })
        XCTAssertFalse(sut.candidates.contains { $0.id == "1" || $0.id == "2" })
        XCTAssertTrue(sut.selectedCandidates.isEmpty)
        XCTAssertFalse(sut.isEditing)
    }

    func testDeleteSelectedCandidatesHandlesErrorGracefully() async throws {
        // Given
        sut.candidates = mockCandidates
        sut.selectedCandidates = Set(["1", "2"]) // Selecting John and Jane

        let failingCandidateId = "1"
        setupMockError(for: .deleteCandidate(id: failingCandidateId))
        mockNetworkService.mockResponses[Endpoint.deleteCandidate(id: "2").url!] = .success(Data())

        let updatedCandidates = mockCandidates.filter { $0.id != "2" }
        try setupMockResponse(for: .candidates, with: updatedCandidates)

        // When
        await sut.deleteSelectedCandidates()
        
        // Then
        XCTAssertEqual(sut.candidates.count, 2) // John should remain as it failed to delete
        XCTAssertTrue(sut.candidates.contains { $0.id == "1" })
        XCTAssertFalse(sut.candidates.contains { $0.id == "2" })
        XCTAssertTrue(sut.selectedCandidates.isEmpty) // Selection is cleared regardless
        XCTAssertFalse(sut.isEditing)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.errorMessage, "Erreur serveur") // Mocked error message
    }

}

// MARK: - Extensions
extension CandidateListViewModel {
    func testHandleError(_ error: Error) {
        handleError(error)
    }
}
