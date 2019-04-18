//
//  ActionSheetViewController.swift
//  askfm
//
//  Created by Ilya Alesker on 26/08/15.
//  Copyright (c) 2015 Ask.fm Europe, Ltd. All rights reserved.
//

import UIKit

public protocol AFMActionSheetControllerDelegate {
    
    func AFMActionSheetWillDismiss()
    
}


@IBDesignable
public class AFMActionSheetController: UIViewController {
    
    public var actionSheetDelegate: AFMActionSheetControllerDelegate?
    
    public enum ControllerStyle : Int {
        case ActionSheet
        case Alert
    }
    
    @IBInspectable public var outsideGestureShouldDismiss: Bool = true
    
    @IBInspectable public var minControlHeight: Int     = 50 {
        didSet { self.updateUI() }
    }
    @IBInspectable public var minTitleHeight: Int       = 50 {
        didSet { self.updateUI() }
    }
    @IBInspectable public var spacing: Int = 8  {
        didSet { self.updateUI() }
    }
    @IBInspectable public var spacingBetweenGroupAndCancel: Int = 8  {
        didSet { self.updateUI() }
    }
    @IBInspectable public var verticalMarginToTop: Int  = 16 {
        didSet { self.updateUI() }
    }
    @IBInspectable public var horizontalMargin: Int     = 16 {
        didSet { self.updateUI() }
    }
    @IBInspectable public var verticalMargin: Int       = 16 {
        didSet { self.updateUI() }
    }
    @IBInspectable public var cornerRadius: Int         = 10 {
        didSet { self.updateUI() }
    }
    
    @IBInspectable public var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5) {
        didSet { self.updateUI() }
    }
    
    @IBInspectable public var spacingColor: UIColor = UIColor.clear {
        didSet { self.updateUI() }
    }
    
    let controllerStyle: ControllerStyle
    
    public private(set) var actions: [AFMAction] = []
    public private(set) var actionControls: [UIControl] = []
    public private(set) var cancelControls: [UIControl] = []
    public private(set) var titleView: UIView?
    
    private var actionControlConstraints: [NSLayoutConstraint] = []
    private var cancelControlConstraints: [NSLayoutConstraint] = []
    
    private var actionSheetTransitioningDelegate: UIViewControllerTransitioningDelegate?
    
    var actionGroupView: UIView = UIView()
    var cancelGroupView: UIView = UIView()
    
    
    // MARK: Initializers
    
    public init(style: ControllerStyle, transitioningDelegate: UIViewControllerTransitioningDelegate) {
        self.controllerStyle = style
        super.init(nibName: nil, bundle: nil)
        self.setupViews()
        self.setupTranstioningDelegate(transitioningDelegate: transitioningDelegate)
    }
    
    public convenience init(style: ControllerStyle) {
        self.init(style: style, transitioningDelegate: AFMActionSheetTransitioningDelegate())
    }
    
    public convenience init(transitioningDelegate: UIViewControllerTransitioningDelegate) {
        self.init(style: .ActionSheet, transitioningDelegate: transitioningDelegate)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.controllerStyle = .ActionSheet
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupViews()
        self.setupTranstioningDelegate(transitioningDelegate: AFMActionSheetTransitioningDelegate())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.controllerStyle = .ActionSheet
        super.init(coder: aDecoder)
        self.setupViews()
        self.setupTranstioningDelegate(transitioningDelegate: AFMActionSheetTransitioningDelegate())
        
    }
    
    private func setupViews() {
        self.setupGroupViews()
        self.setupGestureRecognizers()
        
        self.view.backgroundColor = self.backgroundColor
    }
    
    private func setupGestureRecognizers() {
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                self.view.removeGestureRecognizer(gestureRecognizer)
            }
        }
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(AFMActionSheetController.recognizeGestures(gestureRecognizer:)))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.down
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AFMActionSheetController.recognizeGestures(gestureRecognizer:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        
        self.view.addGestureRecognizer(swipeGestureRecognizer)
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    public func setupTranstioningDelegate(transitioningDelegate: UIViewControllerTransitioningDelegate) {
        self.modalPresentationStyle = .custom
        self.actionSheetTransitioningDelegate = transitioningDelegate
        self.transitioningDelegate = self.actionSheetTransitioningDelegate
    }
    
    
    // MARK: Adding actions
    
    public func addAction(action: AFMAction) {
        let control = UIButton.controlWithAction(action: action)
        self.addAction(action: action, control: control)
    }
    
    public func addCancelAction(action: AFMAction) {
        let control = UIButton.controlWithAction(action: action, hasBoldTitle: true)
        self.addCancelAction(action: action, control: control)
    }
    
    public func addAction(action: AFMAction, control: UIControl) {
        self.addAction(action: action, control: control, isCancelAction: false)
    }
    
    public func addCancelAction(action: AFMAction, control: UIControl) {
        self.addAction(action: action, control: control, isCancelAction: true)
    }
    
    func addAction(action: AFMAction, control: UIControl, isCancelAction: Bool) {
        control.isEnabled = action.enabled
        control.addTarget(self, action:#selector(AFMActionSheetController.handleTaps(sender:)), for: .touchUpInside)
        control.tag = self.actions.count
        
        self.actions.append(action)
        
        if isCancelAction {
            self.cancelControls.append(control)
        } else {
            // when it comes to non cancel controls, we want to position them from top to bottom
            self.actionControls.insert(control, at: 0)
        }
        
        self.addControlToGroupView(control: control, isCancelAction: isCancelAction)
    }
    
    public func addTitle(title: String) {
        let label = UILabel.titleWithText(text: title)
        self.addTitleView(titleView: label)
    }
    
    public func addTitleView(titleView: UIView) {
        self.titleView = titleView
        
        self.titleView!.translatesAutoresizingMaskIntoConstraints = false
        self.actionGroupView.addSubview(self.titleView!)
        self.updateContraints()
    }
    
    
    private func addControlToGroupView(control: UIControl, isCancelAction: Bool) {
        if self.controllerStyle == .ActionSheet {
            self.addControlToGroupViewForActionSheet(control: control, isCancelAction: isCancelAction)
        } else if self.controllerStyle == .Alert {
            self.addControlToGroupViewForAlert(control: control, isCancelAction: isCancelAction)
        }
    }
    
    private func addControlToGroupViewForActionSheet(control: UIControl, isCancelAction: Bool) {
        control.translatesAutoresizingMaskIntoConstraints = false
        if isCancelAction {
            self.cancelGroupView.addSubview(control)
        } else {
            self.actionGroupView.addSubview(control)
        }
        self.updateContraints()
    }
    
    private func addControlToGroupViewForAlert(control: UIControl, isCancelAction: Bool) {
        control.translatesAutoresizingMaskIntoConstraints = false
        self.actionGroupView.addSubview(control)
        self.updateContraints()
    }
    
    private func actionControlsWithTitle() -> [UIView] {
        var views: [UIView] = self.actionControls
        if let titleView = self.titleView {
            views.append(titleView)
        }
        return views
    }
    
    
    // MARK: Control positioning and updating
    
    func updateContraints() {
        if self.controllerStyle == .ActionSheet {
            self.updateContraintsForActionSheet()
        } else if self.controllerStyle == .Alert {
            self.updateContraintsForAlert()
        }
    }
    
    func updateContraintsForActionSheet() {
        self.cancelGroupView.removeConstraints(self.cancelControlConstraints)
        self.cancelControlConstraints = self.constraintsForViews(views: self.cancelControls)
        self.cancelGroupView.addConstraints(self.cancelControlConstraints)
        
        self.actionGroupView.removeConstraints(self.actionControlConstraints)
        self.actionControlConstraints = self.constraintsForViews(views: self.actionControlsWithTitle())
        self.actionGroupView.addConstraints(self.actionControlConstraints)
    }
    
    func updateContraintsForAlert() {
        var views: [UIView] = self.actionControlsWithTitle()
        let cancelViews: [UIView] = self.cancelControls
        views.insert(contentsOf: cancelViews, at: 0)
        self.actionGroupView.removeConstraints(self.actionControlConstraints)
        self.actionControlConstraints = self.constraintsForViews(views: views)
        self.actionGroupView.addConstraints(self.actionControlConstraints)
    }
    
    private func setupGroupViews() {
        if self.controllerStyle == .ActionSheet {
            self.setupGroupViewsForActionSheet()
        } else if self.controllerStyle == .Alert {
            self.setupGroupViewsForAlert()
        }
        self.actionGroupView.backgroundColor = self.spacingColor
        self.cancelGroupView.backgroundColor = self.spacingColor
    }
    
    private func setupGroupViewsForActionSheet() {
        let setupGroupView: (UIView) -> Void = { groupView in
            groupView.removeFromSuperview()
            self.view.addSubview(groupView)
            groupView.clipsToBounds = true
            groupView.layer.cornerRadius = CGFloat(self.cornerRadius)
            groupView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-margin-[groupView]-margin-|",
                                                                    options: .directionLeadingToTrailing,
                                                                    metrics: ["margin": self.horizontalMargin],
                                                                    views: ["groupView": groupView])
            )
        }
        
        setupGroupView(self.actionGroupView)
        setupGroupView(self.cancelGroupView)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=verticalMarginToTop)-[actionGroupView]-spacingBetweenGroupAndCancel-[cancelGroupView]-margin-|",
                                                                options: .directionLeadingToTrailing,
                                                                metrics: ["verticalMarginToTop": self.verticalMarginToTop, "margin": self.verticalMargin, "spacingBetweenGroupAndCancel" : self.spacingBetweenGroupAndCancel],
                                                                views: ["actionGroupView": self.actionGroupView, "cancelGroupView": self.cancelGroupView])
        )
    }
    
    private func setupGroupViewsForAlert() {
        self.actionGroupView.removeFromSuperview()
        self.view.addSubview(self.actionGroupView)
        
        self.actionGroupView.clipsToBounds = true
        self.actionGroupView.layer.cornerRadius = CGFloat(self.cornerRadius)
        self.actionGroupView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-margin-[groupView]-margin-|",
                                                                options: .directionLeadingToTrailing,
                                                                metrics: ["margin": self.horizontalMargin],
                                                                views: ["groupView": self.actionGroupView])
        )
        
        self.view.addConstraint(NSLayoutConstraint(item: self.actionGroupView,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: self.view,
                                                   attribute: .centerY,
                                                   multiplier: 1,
                                                   constant: 0))
    }
    
    private func constraintsForViews(views: [UIView]) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        
        var sibling: UIView?
        for view in views {
            let isLast = view == views.last
            constraints.append(contentsOf: self.horizontalConstraintsForView(view: view))
            constraints.append(contentsOf: self.verticalConstraintsForView(view: view, isLast: isLast, sibling: sibling))
            
            sibling = view
        }
        
        return constraints
    }
    
    private func horizontalConstraintsForView(view: UIView) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|",
                                              options: .directionLeadingToTrailing,
                                              metrics: nil,
                                              views: ["view": view])
    }
    
    private func verticalConstraintsForView(view: UIView, isLast: Bool, sibling: UIView?) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        let height = view != self.titleView ? self.minControlHeight : self.minTitleHeight
        if let sibling = sibling {
            let format = "V:[view(>=height)]-spacing-[sibling]"
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: format,
                                                                          options: .directionLeadingToTrailing,
                                                                          metrics: ["spacing": self.spacing, "height": height],
                                                                          views: ["view": view, "sibling": sibling]) )
        } else {
            let format = "V:[view(>=height)]-0-|"
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: format,
                                                                          options: .directionLeadingToTrailing,
                                                                          metrics: ["height": height],
                                                                          views: ["view": view]) )
        }
        if isLast {
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]",
                                                                          options: .directionLeadingToTrailing,
                                                                          metrics: nil,
                                                                          views: ["view": view]) )
        }
        return constraints
    }
    
    private func updateUI() {
        self.view.backgroundColor = self.backgroundColor
        self.view.removeConstraints(self.view.constraints)
        self.setupGroupViews()
        self.updateContraints()
    }
    
    
    // MARK: Event handling
    
    @objc func handleTaps(sender: UIControl) {
        let index = sender.tag
        let action = self.actions[index]
        if action.enabled {
            self.disableControls()
            
            // Inform delegate
            self.actionSheetDelegate?.AFMActionSheetWillDismiss()
            
            self.dismiss(animated: true, completion: {
                self.enableControls()
                action.handler?(action)
            })
        }
    }
    
    func enableControls() {
        self.setUserInteractionOnControlsEnabled(enabled: true, controls: self.actionControls)
        self.setUserInteractionOnControlsEnabled(enabled: true, controls: self.cancelControls)
    }
    
    func disableControls() {
        self.setUserInteractionOnControlsEnabled(enabled: false, controls: self.actionControls)
        self.setUserInteractionOnControlsEnabled(enabled: false, controls: self.cancelControls)
    }
    
    func setUserInteractionOnControlsEnabled(enabled: Bool, controls: [UIControl]) {
        for control in controls {
            control.isUserInteractionEnabled = enabled
        }
    }
    
    @objc func recognizeGestures(gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: self.view)
        let view = self.view.hitTest(point, with: nil)
        if (view == self.view && self.outsideGestureShouldDismiss) {
            // Inform delegate
            self.actionSheetDelegate?.AFMActionSheetWillDismiss()
            self.dismiss(animated: true, completion: {
            })
        }
    }
}


// MARK: - Default control

extension UIButton {
    class func controlWithAction(action: AFMAction, hasBoldTitle: Bool = false) -> UIButton {
        let button = UIButton()
        button.backgroundColor = UIColor.white
        button.setTitleColor(UIColor(red: 0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0), for: .normal)
        
        if (hasBoldTitle) {
            button.setAttributedTitle(NSAttributedString(string: action.title, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18.0), NSAttributedString.Key.foregroundColor: UIColor(red: 0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)]), for: .normal)
        } else {
            button.setTitle(action.title, for: .normal)
        }
        
        button.setBackgroundColor(color: UIColor.white, forState: .normal)
        button.setBackgroundColor(color: UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0), forState: .highlighted)
        
        return button
    }
    
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
}

extension UILabel {
    class func titleWithText(text: String) -> UILabel {
        let title = UILabel()
        title.text = text
        title.textAlignment = .center
        title.backgroundColor = UIColor.white
        
        return title
    }
}
