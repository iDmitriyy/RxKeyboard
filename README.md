**RxKeyboard**

Simple RxSwift extension to handle standard keyboard events instead of using NotificationCenter.

There are totally 6 events: willBeShown/wasShown, willBeHidden/wasHidden, willChangeFrame/didChangeFrame


Every event is handled with additional info about Keyboard UI state:

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
