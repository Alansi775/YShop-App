//
//  HomeViews.swift
//  YShop
//
//  Created by Mohammed on 26.12.2024.
//

import SwiftUI

struct TrendingHashtagsView: View {
    var body: some View {
        VStack {
            Text("@Trending")
                .font(tenorSans(18))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
            
            HashtagsView(tags: hashtags)
                .padding([.leading, .trailing], 30)
        }
        
    }
}

struct TrendingHashtagsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingHashtagsView()
    }
}
