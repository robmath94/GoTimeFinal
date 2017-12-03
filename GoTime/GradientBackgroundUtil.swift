//
//  GradientBackgroundUtil.swift
//  GoTime
//
//  Created by Robert Mathews on 11/19/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit

extension CAGradientLayer {
   
   func setBackground() -> CAGradientLayer {
      
      let topColor = UIColor(red: (53/255.0), green: (225/255.0), blue: (210/255.0), alpha: 1)
      let bottomColor = UIColor(red: (62/255.0), green: (231/255.0), blue: (165/255.0), alpha: 1)
      
      let gradientColors:[CGColor] = [topColor.cgColor, bottomColor.cgColor]
      let gradientLocations:[NSNumber] = [0.0, 1.0]
      let gradientLayer:CAGradientLayer = CAGradientLayer()
      gradientLayer.colors = gradientColors
      gradientLayer.locations = gradientLocations
      
      return gradientLayer
   }

}
