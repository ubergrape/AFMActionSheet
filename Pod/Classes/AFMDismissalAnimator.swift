//
//  AFMDismissalAnimator.swift
//  Pods
//
//  Created by Ilya Alesker on 26/08/15.
//  Copyright (c) 2015 Ask.fm Europe, Ltd. All rights reserved.
//

import UIKit

public class AFMDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var animator: UIDynamicAnimator?
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as UIViewController?
        
        let initialFrame = transitionContext.initialFrame(for: fromViewController!)
        transitionContext.containerView.addSubview(fromViewController!.view)
        
        let views = Array(fromViewController!.view.subviews.reversed())
        //let viewCount = Double(views.count)
        var index = 0
        
        for view in views {
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                           delay: 0,
                           options: [],
                           animations: {
                            view.transform = CGAffineTransform(translationX: 0, y: initialFrame.height)
                }, completion: nil)
            index += 1
        }
        
        let backgroundColor = fromViewController?.view.backgroundColor!
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       animations: {
                        fromViewController?.view.backgroundColor = backgroundColor?.withAlphaComponent(0)
        }) { _ in
            transitionContext.completeTransition(true)
        }
    }
}
