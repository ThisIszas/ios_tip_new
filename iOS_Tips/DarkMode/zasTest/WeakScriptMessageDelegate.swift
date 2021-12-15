//
//  WeakScriptMessageDelegate.swift
//  Zas tip
//
//  Created by Zas on 2019/02/04.
//  Copyright © 2021 Zas. All rights reserved.
//

import UIKit
import WebKit

class WeakScriptMessageDelegate: NSObject, WKScriptMessageHandler {
    weak open var scriptDelegate: WKScriptMessageHandler?
    
    init(with delegate: WKScriptMessageHandler){
        self.scriptDelegate = delegate;
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.scriptDelegate?.userContentController(userContentController, didReceive: message);
    }
}
