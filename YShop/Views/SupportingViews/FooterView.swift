//
//  HomeViews.swift
//  YShop
//
//  Created by Mohammed on 26.12.2024.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack {
            Image("Openfashion")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Image("Footer")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
