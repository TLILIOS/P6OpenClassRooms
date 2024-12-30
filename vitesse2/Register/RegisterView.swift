//
//  RegisterView.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 11/12/2024.
//

import SwiftUI

// Vue d'inscription pour les nouveaux utilisateurs
// Gère la création de compte et la validation des données
struct RegisterView: View {
    // États pour les champs du formulaire
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo ou titre
                    Text("Créer un compte")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, 30)
                    
                    // Champs de saisie
                    VStack(spacing: 15) {
                        // Champ pour le prénom
                        TextField("Prénom", text: $viewModel.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        // Champ pour le nom
                        TextField("Nom", text: $viewModel.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        // Champ pour l'email
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        // Champ pour le mot de passe
                        SecureField("Mot de passe", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Champ pour la confirmation du mot de passe
                        SecureField("Confirmer le mot de passe", text: $viewModel.confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Bouton d'inscription
                    Button(action: {
                        Task {
                            await viewModel.register()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                    
                    // Lien pour revenir à la connexion
                    Button(action: { dismiss() }) {
                        Text("Already have an account? Log in")
                            .foregroundColor(.blue)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .alert("Erreur", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.isRegistered) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
