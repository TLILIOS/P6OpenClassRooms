//
//  ProfilViewModel.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 13/12/2024.
//
import SwiftUI

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
#Preview {
    InfoRow(title: "Name", value: "Hamdi TLiLi")
}
