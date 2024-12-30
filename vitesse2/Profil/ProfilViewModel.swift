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
//        Task {
////            await fetchCandidate()
//        }
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
            let updatedCandidate: Candidate = try await networkService.request(.updateCandidate(id: candidate.id, candidate: request))
            candidate = updatedCandidate
            editedCandidate = updatedCandidate
            isEditing = false
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func toggleFavorite() async {
        guard !isLoading else { return }
        if !isAdmin {
            return  // Si non admin, on ignore simplement l'action
        }
        
        isLoading = true
        
        do {
            // Mettre à jour l'état local immédiatement pour une meilleure réactivité
            candidate.isFavorite.toggle()
            editedCandidate.isFavorite = candidate.isFavorite
            
            // Utiliser l'endpoint spécifique pour les favoris
            let response: Candidate = try await networkService.request(.toggleFavorite(id: candidate.id))
            candidate = response
            editedCandidate = response
        } catch {
            // En cas d'erreur, restaurer l'état précédent
            candidate.isFavorite.toggle()
            editedCandidate.isFavorite = candidate.isFavorite
            handleError(error)
        }
        
        isLoading = false
    }
    
    func cancelEditing() {
        editedCandidate = candidate
        isEditing = false
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else {
            errorMessage = "Une erreur inattendue s'est produite"
        }
        showAlert = true
        isLoading = false
    }
}
