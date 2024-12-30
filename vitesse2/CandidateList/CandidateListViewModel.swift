//
//  CandidateListViewModel.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 13/12/2024.
//

import Foundation

@MainActor
class CandidateListViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    @Published var searchText = ""
    @Published var isEditing = false
    @Published var selectedCandidates: Set<String> = []
    @Published var showOnlyFavorites = false
    // Dans CandidateListViewModel.swift

    // Modifier la déclaration du networkService
    private let networkService: NetworkServiceProtocol
    let isAdmin: Bool
    // Modifier l'initialisation
    init(networkService: NetworkServiceProtocol = NetworkService.shared,
             isAdmin: Bool,
             shouldFetchOnInit: Bool = true) {
            self.networkService = networkService
            self.isAdmin = isAdmin
            
            if shouldFetchOnInit {
                Task {
                    await fetchCandidates()
                }
            }
        }
    
    var filteredCandidates: [Candidate] {
        // Prepare search term
        let searchTerm = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Filter based on search text
        var filtered = candidates.filter { candidate in
            guard !searchTerm.isEmpty else { return true }
            
            let firstName = candidate.firstName.lowercased()
            let lastName = candidate.lastName.lowercased()
            let email = candidate.email.lowercased()
            let phone = candidate.phone?.lowercased() ?? ""
            
            return firstName.contains(searchTerm) ||
                   lastName.contains(searchTerm) ||
                   email.contains(searchTerm) ||
                   phone.contains(searchTerm)
        }
        
        // Filter based on favorites
        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        return filtered
    }

    
    func fetchCandidates() async {
        isLoading = true
        do {
            candidates = try await networkService.request(.candidates)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func deleteCandidate(_ candidate: Candidate) async {
        isLoading = true
        do {
            try await networkService.requestWithoutResponse(.deleteCandidate(id: candidate.id))
            await fetchCandidates()
        } catch {
            handleError(error)
        }
    }
    
    func toggleSelection(for candidate: Candidate) {
        if selectedCandidates.contains(candidate.id) {
            selectedCandidates.remove(candidate.id)
        } else {
            selectedCandidates.insert(candidate.id)
        }
    }
    
    func deleteSelectedCandidates() async {
        for candidateId in selectedCandidates {
            if let candidate = candidates.first(where: { $0.id == candidateId }) {
                await deleteCandidate(candidate)
            }
        }
        selectedCandidates.removeAll()
        isEditing = false
    }
    
    func deleteSelectedCandidatesSync() {
        Task {
            await deleteSelectedCandidates()
        }
    }
    
    func toggleFavorite(for candidate: Candidate) async {
        if !isAdmin {
            return  // Si non admin, on ignore simplement l'action
        }
        
        isLoading = true
        do {
            let updatedCandidate: Candidate = try await networkService.request(.toggleFavorite(id: candidate.id))
            if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
                candidates[index] = updatedCandidate
            }
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func toggleFavoriteSync(for candidate: Candidate) {
        Task {
            await toggleFavorite(for: candidate)
        }
    }
    
    internal func handleError(_ error: Error) {
        if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else {
            errorMessage = "Une erreur inattendue s'est produite"
        }
        showAlert = true
        isLoading = false
    }
}
