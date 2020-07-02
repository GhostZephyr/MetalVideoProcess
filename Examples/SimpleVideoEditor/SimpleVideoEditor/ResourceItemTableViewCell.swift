//
//  ResourceItemTableViewCell.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/8.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit

class ResourceItemTableViewCell: UITableViewCell {
    @IBOutlet weak var trackIdLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
