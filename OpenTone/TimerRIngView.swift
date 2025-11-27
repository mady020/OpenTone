//
//  TimerRIngView.swift
//  OpenTone
//
//  Created by Student on 27/11/25.
//

import Foundation
import UIKit

class TimerRingView: UIView {
    
    override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        private func setup() {
            backgroundColor = .clear
            // Drawing & animation will be added later
        }
}
