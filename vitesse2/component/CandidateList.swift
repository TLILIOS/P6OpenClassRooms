////
////  SearchBarView.swift
////  vitesse2
////
////  Created by TLiLi Hamdi on 14/12/2024.
////
//
//import SwiftUI
//struct CandidateList: View {
//    @ObservedObject var viewModel: CandidateListViewModel
//    
//    var body: some View {
//        List {
//            ForEach(viewModel.filteredCandidates) { candidate in
//                NavigationLink(destination: ProfilView(candidateId: candidate.id, isAdmin: viewModel.isAdmin)) {
//                    CandidateRowView(candidate: candidate, viewModel: viewModel)
//                }
//            }
//        }
//        .listStyle(PlainListStyle())
//    }
//}
//#Preview {
//    CandidateList(viewModel: .init(isAdmin: false))
//}
