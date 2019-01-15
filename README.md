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
