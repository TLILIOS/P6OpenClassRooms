//
//  ProfileViewModelTests.swift
//  vitesse2Tests
//
//  Created by TLiLi Hamdi on 18/12/2024.
//

import XCTest
@testable import vitesse2

@MainActor
final class ProfileViewModelTests: XCTestCase {
    var mockNetworkService: MockNetworkService!
    var viewModel: ProfileViewModel!
    var mockCandidate: Candidate!

    override func setUp() async throws {
        // Créer un candidat simulé
        mockCandidate = Candidate(
            id: "1",
            firstName: "John",
            lastName: "Doe",
            email: "test@example.com",
            phone: "1234567890",
            note: "Test Note",
            linkedinURL: "https://linkedin.com/in/test",
            isFavorite: false
        )

        // Initialiser le MockNetworkService
        mockNetworkService = MockNetworkService()
        await mockNetworkService.setToken("fake-token")
        
        // Injecter des réponses simulées dans le MockNetworkService
        let candidateData = try JSONEncoder().encode(mockCandidate)
        mockNetworkService.mockResponses = .success(candidateData)

        // Initialiser le ViewModel
        viewModel = ProfileViewModel(candidate: mockCandidate, isAdmin: true, networkService: mockNetworkService)
    }

    func testFetchCandidateSuccess() async throws {
        // Appeler fetchCandidate
        await viewModel.fetchCandidate()
        
        // Vérifier les résultats
        XCTAssertEqual(viewModel.candidate.id, mockCandidate.id)
        XCTAssertEqual(viewModel.candidate.email, mockCandidate.email)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFetchCandidateFailure() async throws {
        // Injecter une erreur spécifique
        mockNetworkService.mockResponses = .failure(NetworkService.NetworkError.missingToken)
        
        // Appeler fetchCandidate
        await viewModel.fetchCandidate()
        
        // Vérifier que le message d'erreur est spécifique
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, "Token d'authentification manquant")
    }

    func testSaveChangesSuccess() async throws {
        // Créer le candidat mis à jour avec les nouvelles valeurs
        var updatedCandidate = mockCandidate!
        updatedCandidate.firstName = "Jane"
        let updatedData = try JSONEncoder().encode(updatedCandidate)
        
        // Créer la requête
        let candidateRequest = CandidateRequest(
            email: mockCandidate.email,
            note: mockCandidate.note ?? "",
            linkedinURL: mockCandidate.linkedinURL ?? "",
            firstName: "Jane",
            lastName: mockCandidate.lastName,
            phone: mockCandidate.phone ?? ""
        )
        
        // Configurer l'endpoint et l'URL
        let endpoint = Endpoint.updateCandidate(id: "1", candidate: candidateRequest)
        guard let url = endpoint.url else {
            XCTFail("URL invalide")
            return
        }
        
        print("URL configurée pour update: \(url.absoluteString)")
        mockNetworkService.mockResponses = .success(updatedData)
        
        // Modifier le prénom
        viewModel.editedCandidate.firstName = "Jane"
        
        // Sauvegarder les changements
        await viewModel.saveChanges()
        
        // Vérifier les résultats
        XCTAssertEqual(viewModel.candidate.firstName, "Jane", 
                      "Le prénom n'a pas été mis à jour. Valeur actuelle: \(viewModel.candidate.firstName)")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testToggleFavoriteSuccess() async throws {
        // Créer un candidat avec favori activé
        var toggledCandidate = mockCandidate!
        toggledCandidate.isFavorite = true
        let toggledData = try JSONEncoder().encode(toggledCandidate)
        
        // Configurer l'endpoint et l'URL
        let endpoint = Endpoint.toggleFavorite(id: "1")
        guard let url = endpoint.url else {
            XCTFail("URL invalide")
            return
        }
        
        print("URL configurée pour toggle: \(url.absoluteString)")
        mockNetworkService.mockResponses = .success(toggledData)
        
        // Exécuter le toggle
        await viewModel.toggleFavorite()
        
        // Vérifier le résultat
        XCTAssertTrue(viewModel.candidate.isFavorite, "Le statut de favori n'a pas été mis à jour.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testToggleFavoriteFailure() async throws {
        mockNetworkService.mockResponses = .failure(NetworkService.NetworkError.missingToken)
        await viewModel.toggleFavorite()
        
        XCTAssertFalse(viewModel.candidate.isFavorite)
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, "Token d'authentification manquant")
    }

    func testCancelEditing() {
        // Modifier les valeurs dans editedCandidate
        viewModel.editedCandidate.firstName = "Jane"
        viewModel.editedCandidate.lastName = "Smith"
        viewModel.isEditing = true
        
        // Annuler les modifications
        viewModel.cancelEditing()
        
        // Vérifier que les modifications ont été annulées
        XCTAssertEqual(viewModel.editedCandidate.firstName, mockCandidate.firstName, 
                      "Le prénom n'a pas été réinitialisé")
        XCTAssertEqual(viewModel.editedCandidate.lastName, mockCandidate.lastName, 
                      "Le nom n'a pas été réinitialisé")
        XCTAssertFalse(viewModel.isEditing, "Le mode édition n'a pas été désactivé")
    }

    // MARK: - HandleError Tests
    
    func testHandleError_InvalidURL() {
        // Arrange
        let error = NetworkService.NetworkError.invalidURL
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "URL invalide")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_Unauthorized() {
        // Arrange
        let error = NetworkService.NetworkError.unauthorized
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Non autorisé")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_ServerError() {
        // Arrange
        let error = NetworkService.NetworkError.serverError(500, "Erreur interne du serveur")
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Erreur interne du serveur")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_MissingToken() {
        // Arrange
        let error = NetworkService.NetworkError.missingToken
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Token d'authentification manquant")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_DecodingError() {
        // Arrange
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Données corrompues")
        )
        let error = NetworkService.NetworkError.decodingError(decodingError)
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur de décodage"))
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_Unknown() {
        // Arrange
        let error = NetworkService.NetworkError.unknown
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Erreur inconnue")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_NonNetworkError() {
        // Arrange
        struct CustomError: LocalizedError {
            var errorDescription: String? {
                return "Erreur personnalisée"
            }
        }
        let error = CustomError()
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Erreur personnalisée")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_SimpleError() {
        // Arrange
        struct SimpleError: Error {}
        let error = SimpleError()
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Le message d'erreur ne devrait pas être vide")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_CustomErrorWithDescription() {
        // Arrange
        class CustomDescriptionError: NSError {
            override var description: String {
                return "Description personnalisée de l'erreur"
            }
            
            override var localizedDescription: String {
                return description
            }
            
            init() {
                super.init(domain: "CustomErrorDomain", code: 0, userInfo: nil)
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        let error = CustomDescriptionError()
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Description personnalisée de l'erreur",
                     "Le message devrait être exactement la description personnalisée")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_NSError() {
        // Arrange
        let domain = "TestErrorDomain"
        let code = 42
        let userInfo = [NSLocalizedDescriptionKey: "Erreur NSError personnalisée"]
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Erreur NSError personnalisée")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_ErrorWithoutDescription() {
        // Arrange
        enum CustomEnum: Error {
            case someError
        }
        let error = CustomEnum.someError
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertFalse(viewModel.errorMessage.isEmpty, 
                      "Même sans description personnalisée, le message ne devrait pas être vide")
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleError_ResetsPreviousError() {
        // Arrange
        viewModel.errorMessage = "Erreur précédente"
        viewModel.showAlert = false
        let error = NetworkService.NetworkError.unknown
        
        // Act
        viewModel.testHandleError(error)
        
        // Assert
        XCTAssertEqual(viewModel.errorMessage, "Erreur inconnue", 
                      "Le message d'erreur précédent devrait être remplacé")
        XCTAssertTrue(viewModel.showAlert, 
                     "showAlert devrait être true même s'il était false avant")
        XCTAssertFalse(viewModel.isLoading)
    }
}
