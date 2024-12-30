import SwiftUI

// Vue principale listant tous les candidats
// Permet la recherche, le filtrage des favoris et l'accès aux détails
struct CandidatesListView: View {
    // ViewModel gérant la logique et les données
    @StateObject private var viewModel: CandidateListViewModel
    // États pour gérer les différentes vues modales
    @State private var showingAddSheet = false
    @State private var showingEditView = false
    @State private var selectedCandidate: Candidate? = nil
    
    init(isAdmin: Bool) {
        _viewModel = StateObject(wrappedValue: CandidateListViewModel(isAdmin: isAdmin))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBarView(text: $viewModel.searchText)
                
                List(viewModel.filteredCandidates) { candidate in
                    Button(action: {
                        selectedCandidate = candidate
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(candidate.firstName) \(candidate.lastName)")
                                    .font(.headline)
                                Text(candidate.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                                .foregroundColor(candidate.isFavorite ? .yellow : .gray)
                        }
                    }
                }
                .listStyle(.plain) // Simplifie l'apparence
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        showingEditView = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showOnlyFavorites.toggle()
                    }) {
                        Image(systemName: "star")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Candidates")
                            .font(.headline)
                        if viewModel.isAdmin {
                            Button(action: { showingAddSheet = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddSheet) {
                AddCandidateView(isPresented: $showingAddSheet)
                    .interactiveDismissDisabled()
            }
            .onChange(of: showingAddSheet) { oldValue, newValue in
                if !newValue {
                    // La vue d'ajout a été fermée, rafraîchir la liste
                    Task {
                        await viewModel.fetchCandidates()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditView) {
                EditableCandidatesListView(isAdmin: viewModel.isAdmin)
                    .interactiveDismissDisabled()
            }
            .onChange(of: showingEditView) { oldValue, newValue in
                if !newValue {
                    // La vue d'édition a été fermée, rafraîchir la liste
                    Task {
                        await viewModel.fetchCandidates()
                    }
                }
            }
            .fullScreenCover(item: $selectedCandidate) { candidate in
                ProfilView(profile: candidate, isAdmin: viewModel.isAdmin)
                    .interactiveDismissDisabled()
                    .edgesIgnoringSafeArea(.all)
            }
            .onChange(of: selectedCandidate) { oldValue, newValue in
                if newValue == nil {
                    // Le profil a été fermé, rafraîchir la liste
                    Task {
                        await viewModel.fetchCandidates()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                Task {
                    await viewModel.fetchCandidates()
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Supprime le bouton "< Back"
    }
}

struct CandidateListView_Previews: PreviewProvider {
    static var previews: some View {
        CandidatesListView(isAdmin: false)
    }
}
