//
//  Item.swift
//  Whence the Rave?
//
//  Created by Jason Mark Allen on 07/05/2025.
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
