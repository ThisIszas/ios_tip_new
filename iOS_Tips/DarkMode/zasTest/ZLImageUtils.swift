//
//  ZLImageUtils.swift
//  DarkMode
//
//  Created by zas on 2022/1/16.
//  Copyright © 2022 https://github.com/wsl2ls   ----- . All rights reserved.
//

import UIKit

struct ZLNumberDotStyle{
    var radius = 9.0 /// 圆形的半径
    var leftMargin = 5.0;   /// 文字左边距
    var rightMargin = 4.0;  /// 文字右边距
    
    var useGradientBGColor: Bool = false;  /// 是否使用渐变背景色, 为true时bgColor失效, false时gradientStartColor, gradientEndColor失效
    var bgColor: UIColor?; /// 不使用渐变色时的背景色
    var gradientStartColor: UIColor?; /// 渐变色起始颜色
    var gradientEndColor: UIColor?; /// 渐变色结束颜色
    
    var textColor = UIColor.white; /// 数字文字显示的颜色
    var font = UIFont.systemFont(ofSize: 12, weight: .medium);  /// 文字字体
    
    var _bgColor: UIColor{
        get{
            return self.bgColor ?? UIColor.red;
        }
    }
    var _gradientStartColor: UIColor{
        get{
            return self.gradientStartColor ?? UIColor.purple;
        }
    }
    var _gradientEndColor: UIColor{
        get{
            return self.gradientEndColor ?? UIColor.red;
        }
    }
}

extension UIImage {
    /// 获取指定大小的红色圆点图片
    static func getAlertDot(with size: CGSize, color: UIColor = UIColor.red) -> UIImage?{
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale);
        let context = UIGraphicsGetCurrentContext();
        
        context?.addArc(center: CGPoint(x: size.width / 2, y: size.height/2), radius: size.width / 2, startAngle: 0, endAngle: 2*Double.pi, clockwise: true);
        context?.setFillColor(color.cgColor);
        
        context?.drawPath(using: .fill)
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    /// 获取带数字的badge图片
    static func getNumberBadge(with numStr: String, styleConfig: ZLNumberDotStyle) -> UIImage?{
        let radius = styleConfig.radius;
        let margin = styleConfig.leftMargin + styleConfig.rightMargin;
        /// 当显示需要的范围大于 直径 + margin后, 中间的矩形的宽度
        var rectWidth = 0.0;
        let stringSize = numStr.sizeWith(styleConfig.font, CGSize(width: 300, height: radius*2));
        if (stringSize.width + margin) > radius*2{
            /// 宽度加1后, 显示显示效果更平滑
            rectWidth = stringSize.width + margin - radius*2 + 1;
        }
        let totalWidth = radius * 2 + rectWidth;
        /// 文字position 的Y
        let numStrDrawPointY = (radius*2 - stringSize.height) / 2;
        /// 最终大小
        let finalSize = CGSize.init(width: totalWidth, height: radius*2);
        
        UIGraphicsBeginImageContextWithOptions(finalSize, false, UIScreen.main.scale);
        let context = UIGraphicsGetCurrentContext();
        
        let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: CGFloat(radius), startAngle: Double.pi/2, endAngle: Double.pi*1.5, clockwise: true); /// 先画左边的半圆
        path.addLine(to: CGPoint(x: radius + rectWidth, y: 0)); /// 画线到右边半圆的起始位置
        path.addArc(withCenter: CGPoint(x: radius + rectWidth, y: radius), radius: CGFloat(radius), startAngle: Double.pi*1.5, endAngle: Double.pi/2, clockwise: true); /// 画右边半圆
        path.addLine(to: CGPoint(x: radius, y: radius*2)); /// 画线到左边半圆的下面
        path.close();
        /// 添加指定的path
        context?.addPath(path.cgPath);

        if !styleConfig.useGradientBGColor{
            /// 背景色为纯色
            context?.setFillColor(styleConfig._bgColor.cgColor);
            context?.drawPath(using: .fill)
        }
        else{
            /// 背景色是渐变色
            context?.clip();
            context?.saveGState()
            self.addGradientToCGContext(context, startColor: styleConfig._gradientStartColor, endColor: styleConfig._gradientEndColor, size: finalSize)
            context?.restoreGState()
        }
        /// 将要显示的文字画到content上
        (numStr as NSString).draw(at: CGPoint(x: styleConfig.leftMargin, y: numStrDrawPointY), withAttributes: [
            NSAttributedString.Key.foregroundColor: styleConfig.textColor,
            NSAttributedString.Key.font: styleConfig.font
        ])
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    static func addGradientToCGContext(_ context: CGContext?, startColor: UIColor, endColor: UIColor, size finalSize: CGSize){
        ///画渐变
        let colorSpace = CGColorSpaceCreateDeviceRGB()
                
        guard let startColorComponents = startColor.cgColor.components else {return}
        guard let endColorComponents = endColor.cgColor.components else {return};
        
        let colorComponents: [CGFloat]
            = [startColorComponents[0], startColorComponents[1], startColorComponents[2], startColorComponents[3], endColorComponents[0], endColorComponents[1], endColorComponents[2], endColorComponents[3]]
                
        let locations:[CGFloat] = [0.0, 1.0]
                
        guard let gradient = CGGradient(colorSpace: colorSpace,colorComponents: colorComponents,locations: locations,count: 2) else {return}

        let startPoint = CGPoint(x: 0, y: finalSize.height)
        let endPoint = CGPoint(x: finalSize.width,y: finalSize.height)

        context?.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))
    }
}

extension String {
    func sizeWith(_ font : UIFont , _ maxSize : CGSize) ->CGSize {
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        var attributes : [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key.font] = font
        let textBouds = self.boundingRect(with: maxSize,
                                                  options: options,
                                                  attributes: attributes,
                                                  context: nil)
        return textBouds.size
    }
}
