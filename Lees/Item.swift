//
//  Item.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
