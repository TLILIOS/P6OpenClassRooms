//
//  ProfilViewModel.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 13/12/2024.
//

import Foundation

// ViewModel gérant la logique métier du profil candidat
@MainActor
class ProfileViewModel: ObservableObject {
    // Propriétés publiées pour la mise à jour de l'interfac
    @Published var candidate: Candidate
    @Published var editedCandidate: Candidate
    @Published var isEditing: Bool = false
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    
    // Service réseau et droits d'administration
    var networkService: NetworkServiceProtocol
    let isAdmin: Bool
    
    // MARK: - Initialization
    init(candidate: Candidate, isAdmin: Bool, networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.candidate = candidate
        self.editedCandidate = candidate
        self.isAdmin = isAdmin
        self.networkService = networkService
    }
    
    // MARK: - Candidate Management
    func fetchCandidate() async {
        isLoading = true
        do {
            let fetchedCandidate: Candidate = try await networkService.request(.candidate(id: candidate.id))
            candidate = fetchedCandidate
            editedCandidate = fetchedCandidate
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func saveChanges() async {
        isLoading = true
        do {
            let request = CandidateRequest(
                email: editedCandidate.email,
                note: editedCandidate.note,
                linkedinURL: editedCandidate.linkedinURL,
                firstName: editedCandidate.firstName,
                lastName: editedCandidate.lastName,
                phone: editedCandidate.phone
            )
            
            // Effectuer la requête
            let updatedCandidate: Candidate = try await networkService.request(.updateCandidate(id: candidate.id, candidate: request))
            
            // Mettre à jour les propriétés
            self.candidate = updatedCandidate
            self.editedCandidate = updatedCandidate
            self.isEditing = false
            isLoading = false
        } catch {
            handleError(error)
            isLoading = false
        }
    }

    
    func toggleFavorite() async {
        guard !isLoading else { return }
        if !isAdmin {
            return  // Si non admin, on ignore simplement l'action
        }
        
        isLoading = true
        
        do {
            // Utiliser l'endpoint spécifique pour les favoris
            let response: Candidate = try await networkService.request(.toggleFavorite(id: candidate.id))
            
            // Mettre à jour l'état avec la réponse du serveur
            self.candidate = response
            self.editedCandidate = response
            
            isLoading = false
        } catch {
            handleError(error)
            isLoading = false
        }
    }
    
    func cancelEditing() {
        editedCandidate = candidate
        isEditing = false
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else {
            errorMessage = error.localizedDescription
        }
        showAlert = true
        isLoading = false
    }
    
    #if DEBUG
    /// Méthode utilisée uniquement pour les tests
    func testHandleError(_ error: Error) {
        handleError(error)
    }
    #endif
}
