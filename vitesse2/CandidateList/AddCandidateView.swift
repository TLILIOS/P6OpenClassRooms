//
//  AddCandidateView.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 14/12/2024.
//

import SwiftUI
struct AddCandidateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddCandidateViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $viewModel.firstName)
                    TextField("Last Name", text: $viewModel.lastName)
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $viewModel.phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("LinkedIn URL", text: $viewModel.linkedinURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextEditor(text: $viewModel.note)
                        .frame(height: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("New Candidate")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveCandidate() {
                                isPresented = false
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .navigationViewStyle(.stack)
    }
}
