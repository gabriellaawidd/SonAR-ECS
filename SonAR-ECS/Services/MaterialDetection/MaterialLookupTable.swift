//
//  MaterialLookupTable.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import Foundation

struct MaterialLookupTable: Codable {
    let soft: [String]
    let hard: [String]
}

enum MaterialLookupLoader {
    static func load (filename: String = "VisionMaterialLookup") -> MaterialLookupTable {
        MaterialLookupTable(
            soft: [
                "backpack", "pillow", "sofa", "armchair", "curtain", "jacket", "hoodie",
                "clothing", "stuffed_animals", "scarf", "sock", "textile", "rug", "carpet",
                "cushion", "bed", "blanket", "quilt", "mattress", "sweater", "towel",
                "doll", "plush", "fleece", "fabric", "cloth", "sponge", "pillowcase",
                "couch", "velvet", "wool", "cotton", "comforter", "duvet",
                "shoe", "shoes", "sneaker", "running_shoe", "boot", "slipper", "sandal",
                "shirt", "jeans", "pants"
            ],
            hard: [
                "whiteboard", "chalkboard", "desk", "table", "chair", "folding_chair", "stool",
                "desktop_computer", "laptop", "television", "door", "window", "cabinet", "bookshelf",
                "book", "wood_natural", "wood_processed", "brick", "trash_can", "clock", "bottle", "cup",
                "mouse", "remote", "keyboard", "cell phone", "clock", "scissors", "marker",
                "wall", "floor", "tile", "concrete", "metal", "plastic", "glass", "wood",
                "hardwood", "flooring"
            ]
        )
    }
}
