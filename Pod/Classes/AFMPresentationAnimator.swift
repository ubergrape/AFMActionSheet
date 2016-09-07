//
//  AFMPresentationAnimator.swift
//  Pods
//
//  Created by Ilya Alesker on 26/08/15.
//  Copyright (c) 2015 Ask.fm Europe, Ltd. All rights reserved.
//

import UIKit

public class AFMPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }

    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as UIViewController!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as UIViewController!

        let finalFrame = transitionContext.initialFrameForViewController(fromViewController)

        toViewController.view.frame = finalFrame
        transitionContext.containerView()!.addSubview(toViewController.view)

        let views = toViewController.view.subviews
        let viewCount = Double(views.count)
        var index = 0

        for view in views {
            view.transform = CGAffineTransformMakeTranslation(0, finalFrame.height)
            UIView.animateWithDuration(self.transitionDuration(transitionContext),
                delay: 0,
                options: [],
                animations: {
                    view.transform = CGAffineTransformIdentity;
                }, completion: nil)
            index += 1
        }

        let backgroundColor = toViewController.view.backgroundColor!
        toViewController.view.backgroundColor = backgroundColor.colorWithAlphaComponent(0)

        UIView.animateWithDuration(self.transitionDuration(transitionContext),
            animations: { _ in
                toViewController.view.backgroundColor = backgroundColor
            }) { _ in
                transitionContext.completeTransition(true)
        }
    }
}