//
//  CartItem.swift
//  YShop
//
//  Created by Mohammed on 27.12.2024.
//

import Foundation

class CartItem {
    var product: Product
    var count: Int = 0
    
    
    init(product: Product, count: Int){
        self.product = product
        self.count = count
    }
    
}
