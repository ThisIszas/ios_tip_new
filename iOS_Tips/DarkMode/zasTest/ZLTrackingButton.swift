//
//  ZLTrackingButton.swift
//
//
//  Created by Zas on 2022/7/29.
//  Copyright © 2022 Zas. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ZLTrackingButton: UIButton {
    var eventTrackCategory: String?;
    var eventTrackParams: [String: Any]?;
    
    static func doMethodSwizzling() {        
        let originalSendActionSEL: Selector = #selector(ZLTrackingButton.sendAction(_:to:for:));
        let originalSendActionMethod = class_getInstanceMethod(ZLTrackingButton.self, originalSendActionSEL)
        
        let newSendActionSEL: Selector = #selector(ZLTrackingButton.trackAction(_:to:for:));
        let newSendActionMethod = class_getInstanceMethod(ZLTrackingButton.self, newSendActionSEL);
        
        guard let newMethod = newSendActionMethod, let oldMethod = originalSendActionMethod else{
            return
        }
        let addMethodSuccess = class_addMethod(ZLTrackingButton.self, originalSendActionSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        
        if addMethodSuccess{
            class_replaceMethod(ZLTrackingButton.self, newSendActionSEL, method_getImplementation(oldMethod), method_getTypeEncoding(oldMethod))
        }
        else{
            method_exchangeImplementations(oldMethod, newMethod)
        }
        
    }
    
    @objc dynamic func trackAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if let eventCategory = self.eventTrackCategory, let eventParam = self.eventTrackParams{
            if let target = target {
                /// RxSwift触发的情况
                let eventTypeInt = ZLRuntimeOCHelper.getValueForClass(target, className: "RxCocoa.ControlTarget", keyName: "controlEvents")
                
                if eventTypeInt != -100, UIControl.Event.init(rawValue: UInt(eventTypeInt)) == .touchDown{
                    print("上传 eventCategory: \(eventCategory)")
                }
            }
            else{
                /// 正常addTarget的情况
                print("上传")
            }
        }
        
        self.trackAction(action, to: target, for: event);
    }
}
