//
//  RxKeyboard.swift
//  RxKeyboard
//
//  Created by Dmitriy Ignatyev on 15/01/2019.
//  Copyright © 2019 Dmitriy Ignatyev. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

/**
 - Цепочка событий при показе: willChangeFrame, willBeShown, didChangeFrame, wasShown
 - Цепочка событий при скрытии: willChangeFrame, willBeHidden, didChangeFrame, wasHidden
 */
protocol RxKeyboardNotificator: AnyObject {
    var willBeShown: Signal<RxKeyboardAnimationParams> { get }
    var wasShown: Signal<CGRect> { get }
    
    var willBeHidden: Signal<RxKeyboardAnimationParams> { get }
    var wasHidden: Signal<CGRect> { get }
    
    var willChangeFrame: Signal<RxKeyboardAnimationParams> { get }
    var didChangeFrame: Signal<CGRect> { get }
}

final class RxKeyboard: RxKeyboardNotificator {
    
    static let shared: RxKeyboardNotificator = RxKeyboard()
    
    // MARK: RxKeyboardNotificator protocol properties:
    let willBeShown: Signal<RxKeyboardAnimationParams>
    let wasShown: Signal<CGRect>
    
    let willBeHidden: Signal<RxKeyboardAnimationParams>
    let wasHidden: Signal<CGRect>
    
    let willChangeFrame: Signal<RxKeyboardAnimationParams>
    let didChangeFrame: Signal<CGRect>
    
    // Private properties
    // CGRect - это Frame клавиатуры. Всегда равен значению, когда она была полностью видна на экране
    private let _willBeShown = PublishRelay<RxKeyboardAnimationParams>()
    private let _wasShown = PublishRelay<CGRect>()
    
    private let _willBeHidden = PublishRelay<RxKeyboardAnimationParams>()
    private let _wasHidden = PublishRelay<CGRect>()
    
    private let _willChangeFrame = PublishRelay<RxKeyboardAnimationParams>()
    private let _didChangeFrame = PublishRelay<CGRect>() // Финальное значение после изменения размера
    
    private let disposeBag = DisposeBag()
    
    private init() {
        willBeShown = _willBeShown.asSignal()
        wasShown = _wasShown.asSignal()
        
        willBeHidden = _willBeHidden.asSignal()
        wasHidden = _wasHidden.asSignal()
        
        willChangeFrame = _willChangeFrame.asSignal()
        didChangeFrame = _didChangeFrame.asSignal()
        
        performBindings()
    }
}

extension RxKeyboard {
    // MARK: Bindings
    
    private func performBindings() {
        bindShowingEvents()
        bindHidingEvents()
        bindChangingFrameEvents()
    }
    
    private func bindShowingEvents() {
        let willShowEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
        
        willShowEvent
            .map { notification -> RxKeyboardAnimationParams? in
                return type(of: self).animationParams(notification)
            }
            .filterNil().bind(to: _willBeShown).disposed(by: disposeBag)
        
        let didShowEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardDidShowNotification)
        
        didShowEvent
            .map { notification -> CGRect? in
                return type(of: self).finalFrame(notification)
            }
            .filterNil().bind(to: _wasShown).disposed(by: disposeBag)
    }
    
    private func bindHidingEvents() {
        let willHideEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        
        willHideEvent
            .map { notification -> RxKeyboardAnimationParams? in
                return type(of: self).animationParams(notification)
            }
            .filterNil().bind(to: _willBeHidden).disposed(by: disposeBag)
        
        let didHideEvent = NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification)
        
        didHideEvent
            .map { notification -> CGRect? in
                return type(of: self).initialFrame(notification)
            }
            .filterNil().bind(to: _wasHidden).disposed(by: disposeBag)
    }
    
    private func bindChangingFrameEvents() {
        let willChangeFrameEvent = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillChangeFrameNotification)
        
        willChangeFrameEvent
            .map { notification -> RxKeyboardAnimationParams? in
                return type(of: self).animationParams(notification)
            }
            .filterNil().bind(to: self._willChangeFrame).disposed(by: disposeBag)
        
        let didChangeFrameEvent = NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidChangeFrameNotification)
        
        didChangeFrameEvent
            .map { notification -> CGRect? in
                return type(of: self).finalFrame(notification)
            }
            .filterNil().bind(to: self._didChangeFrame).disposed(by: disposeBag)
    }
}

extension RxKeyboard {
    // MARK: Reusable Methods
    
    static private func animationParams(_ notification: Notification) -> RxKeyboardAnimationParams? {
        guard let initialFrame = initialFrame(notification),
            let finalFrame = finalFrame(notification),
            let animationTrait = animationTrait(notification) else { return nil }
        
        return RxKeyboardAnimationParams(initialFrame: initialFrame,
                                         finalFrame: finalFrame,
                                         animationTrait: animationTrait)
    }
    
    static private func initialFrame(_ notification: Notification) -> CGRect? {
        guard let info = notification.userInfo,
            let initialFrameValue = info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return nil }
        
        return initialFrameValue.cgRectValue
    }
    
    static private func finalFrame(_ notification: Notification) -> CGRect? {
        guard let info = notification.userInfo,
            let finalFrameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil }
        
        return finalFrameValue.cgRectValue
    }
    
    static private func animationTrait(_ notification: Notification) -> RxKeyboardAnimationTrait? {
        guard let info = notification.userInfo else { return nil }
        
        let animationOptions: UIView.AnimationOptions?
        if let animationOptionsRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
            animationOptions = UIView.AnimationOptions(rawValue: UInt(animationOptionsRaw) << 16)
        } else {
            animationOptions = nil
        }
        
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        
        return RxKeyboardAnimationTrait(animationOptions: animationOptions, duration: duration)
    }
}

struct RxKeyboardAnimationParams {
    
    let initialFrame: CGRect
    let finalFrame: CGRect
    let animationTrait: RxKeyboardAnimationTrait
    
    init(initialFrame: CGRect, finalFrame: CGRect, animationTrait: RxKeyboardAnimationTrait) {
        self.initialFrame = initialFrame
        self.finalFrame = finalFrame
        self.animationTrait = animationTrait
    }
}

struct RxKeyboardAnimationTrait {
    
    let animationOptions: UIView.AnimationOptions
    let duration: TimeInterval
    
    init(animationOptions: UIView.AnimationOptions, duration: TimeInterval) {
        self.animationOptions = animationOptions
        self.duration = duration
    }
    
    init?(animationOptions: UIView.AnimationOptions?, duration: TimeInterval?) {
        guard let options = animationOptions, let duration = duration else { return nil }
        self.init(animationOptions: options, duration: duration)
    }
}
