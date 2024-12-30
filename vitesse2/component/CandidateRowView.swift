//
//  SearchBarView.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 14/12/2024.
//

import SwiftUI
struct CandidateRowView: View {
    let candidate: Candidate
    @ObservedObject var viewModel: CandidateListViewModel
    
    var body: some View {
        HStack {
            if viewModel.isEditing {
                Circle()
                    .fill(viewModel.selectedCandidates.contains(candidate.id) ? Color.blue : Color.gray)
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading) {
                Text("\(candidate.firstName) \(candidate.lastName)")
                    .font(.headline)
                Text(candidate.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !viewModel.isEditing && viewModel.isAdmin {
                Image(systemName: candidate.isFavorite ? "star.fill" : "star")
                    .foregroundColor(candidate.isFavorite ? .yellow : .gray)
                    .onTapGesture {
                        Task {
                            await viewModel.toggleFavorite(for: candidate)
                        }
                    }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isEditing {
                viewModel.toggleSelection(for: candidate)
            }
        }
    }
}
//#Preview {
//    CandidatesListView(isAdmin: true)
//}
