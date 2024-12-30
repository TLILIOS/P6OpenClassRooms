//
//  SearchBarView.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 14/12/2024.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        TextField("Search", text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .disableAutocorrection(true)
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarView(text: .constant("type your search here"))
    }
}

