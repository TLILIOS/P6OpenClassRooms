//
//  ProfilView.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 13/12/2024.
//

import SwiftUI

// Vue détaillée d'un candidat
// Permet la consultation et la modification des informations
struct ProfilView: View {
    // ViewModel gérant les données et la logique du profil
    @StateObject var viewModel: ProfileViewModel
    // Pour fermer la vue modale
    @Environment(\.presentationMode) var presentationMode
    
    init(profile: Candidate, isAdmin: Bool) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(candidate: profile, isAdmin: isAdmin))
    }
    
    var body: some View {
        NavigationView {
            Group {
                ScrollView {
                    VStack(spacing: 20) {
                        // En-tête avec nom et étoile
                        HStack {
                            Text(viewModel.candidate.fullName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if !viewModel.isEditing {
                                Button(action: {
                                    if viewModel.isAdmin {
                                        Task {
                                            await viewModel.toggleFavorite()
                                        }
                                    }
                                }) {
                                    Image(systemName: viewModel.candidate.isFavorite ? "star.fill" : "star")
                                        .foregroundColor(viewModel.candidate.isFavorite ? .yellow : .gray)
                                        .font(.title2)
                                }
                                .disabled(!viewModel.isAdmin)
                            }
                        }
                        .padding(.horizontal)
                        
                        if !viewModel.isEditing {
                            // Mode lecture
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "Téléphone", value: viewModel.candidate.phone ?? "Non renseigné")
                                InfoRow(title: "Email", value: viewModel.candidate.email)
                                
                                if let linkedin = viewModel.candidate.linkedinURL, !linkedin.isEmpty {
                                    InfoRow(title: "LinkedIn", value: linkedin)
                                }
                                
                                if let note = viewModel.candidate.note, !note.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Notes")
                                            .font(.headline)
                                        Text(note)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                        } else {
                            // Mode édition
                            VStack(spacing: 15) {
                                TextField("Prénom", text: $viewModel.editedCandidate.firstName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Nom", text: $viewModel.editedCandidate.lastName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Email", text: $viewModel.editedCandidate.email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                
                                TextField("Entrez le numéro de téléphone", text: Binding(
                                    get: { viewModel.editedCandidate.phone ?? "" },
                                    set: { viewModel.editedCandidate.phone = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                
                                TextField("LinkedIn URL", text: Binding(
                                    get: { viewModel.editedCandidate.linkedinURL ?? "" },
                                    set: { viewModel.editedCandidate.linkedinURL = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.URL)
                                
                                TextField("Notes", text: Binding(
                                    get: { viewModel.editedCandidate.note ?? "" },
                                    set: { viewModel.editedCandidate.note = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .opacity(viewModel.isLoading ? 0.3 : 1)
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                if viewModel.isAdmin {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.isEditing {
                            Button("Done") {
                                Task {
                                    await viewModel.saveChanges()
                                }
                            }
                        } else {
                            Button("Edit") {
                                viewModel.isEditing = true
                            }
                        }
                    }
                }
            }
            .alert("Erreur", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .navigationViewStyle(.stack)
        .edgesIgnoringSafeArea(.all)
        .task {
            await viewModel.fetchCandidate()
        }
    }
}
