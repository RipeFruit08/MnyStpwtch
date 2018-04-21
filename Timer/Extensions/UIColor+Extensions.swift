//
//  UIColor+Extensions.swift
//  Timer
//
//  https://stackoverflow.com/questions/38355288/change-navigation-bar-bottom-border-color-swift
//
//  Created by Stephen Kim on 4/21/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    // this was used to se a shadowImage on the navbars. Ultimately i decided not to use this
    // keeping this around because i might use it in the future
    func as1ptImage() -> UIImage {
        print("UIColor.as1ptImage")
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    func asImage(width: Double, height: Double) -> UIImage {
        print("UIColor.asImage")
        let rect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
