//
//  ItemCell.swift
//  Word Search
//
//  Created by Brian Kim on 2020-08-26.
//  Copyright © 2020 Brian Kim. All rights reserved.
//

import UIKit

// ItemCell class for reuse
class ItemCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setData(alphabet: String) {
        textLabel.text = alphabet
    }
}
