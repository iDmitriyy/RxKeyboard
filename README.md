**RxKeyboard**

RxKeyboard provides a reactive way of handling standard keyboard events instead of using NotificationCenter.

There are totally 6 events: willBeShown/wasShown, willBeHidden/wasHidden, willChangeFrame/didChangeFrame

Every event contains additional UI information about Keyboard:

	struct RxKeyboardAnimationParams {
	    let initialFrame: CGRect
	    let finalFrame: CGRect
	    let animationTrait: RxKeyboardAnimationTrait
	}

	struct RxKeyboardAnimationTrait {
	    let animationOptions: UIView.AnimationOptions
	    let duration: TimeInterval
	}
	
So if you need to change scrollView insets for example, it will be something like this:

	rxKeyboard.willBeShown.emit(onNext: { [weak self] params in
        self?.setScrollViewBottomInset(params.finalFrame.size.height,
                                       duration: params.animationTrait.duration,
                                       animationOptions: params.animationTrait.animationOptions)
    }).disposed(by: disposeBag)

If you need to get addtional values, such as 'currentFrame' or 'isVisible' for example, you can combine provided 6 events using Rx operators to achieve it.
