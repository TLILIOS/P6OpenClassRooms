import SwiftUI

// Vue permettant la sélection et la suppression multiple de candidats
// Accessible uniquement en mode édition
struct EditableCandidatesListView: View {
    // ViewModel partagé avec CandidatesListView
    @StateObject private var viewModel: CandidateListViewModel
    // États pour la gestion de l'interface
    @State private var showingAddSheet = false
    @State private var showConfirmationAlert = false
    @Environment(\.presentationMode) var presentationMode

    init(isAdmin: Bool) {
        _viewModel = StateObject(wrappedValue: CandidateListViewModel(isAdmin: isAdmin))
    }

    var body: some View {
        NavigationView {
            VStack {
                // Barre de recherche
                SearchBarView(text: $viewModel.searchText)
                    .padding([.leading, .trailing])

                // Liste des candidats
                List {
                    ForEach(viewModel.filteredCandidates) { candidate in
                        HStack {
                            // Indicateur de sélection
                            Circle()
                                .fill(viewModel.selectedCandidates.contains(candidate.id) ? Color.blue : Color.gray)
                                .frame(width: 20, height: 20)

                            // Nom complet
                            Text("\(candidate.firstName) \(candidate.lastName)")
                                .padding(.leading, 8)

                            Spacer()

                            // Indicateur de favori
                            Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                                .foregroundColor(candidate.isFavorite ? .yellow : .gray)
                        }
                        .contentShape(Rectangle()) // Permet de rendre toute la ligne cliquable
                        .onTapGesture {
                            viewModel.toggleSelection(for: candidate)
                        }
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.selectedCandidates.removeAll()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Candidates")
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        showConfirmationAlert = true
                    }
                    .disabled(viewModel.selectedCandidates.isEmpty)
                    .foregroundColor(viewModel.selectedCandidates.isEmpty ? .gray : .red)
                }
            }
            .alert("Confirm Deletion", isPresented: $showConfirmationAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteSelectedCandidates()
                        await viewModel.fetchCandidates()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                if viewModel.candidates.isEmpty {
                    Task {
                        await viewModel.fetchCandidates()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct EditableCandidatesListView_Previews: PreviewProvider {
    static var previews: some View {
        EditableCandidatesListView(isAdmin: true)
    }
}
