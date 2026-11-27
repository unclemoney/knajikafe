extends Node


func is_reduced() -> bool:
	var profile := GameController.current_profile
	return profile != null and bool(profile.settings.get("reduced_motion", false))


func _immediate(node: CanvasItem) -> Tween:
	var tween := node.get_tree().create_tween()
	tween.tween_interval(0.0)
	return tween


func pop_in(node: CanvasItem, duration: float = 0.3, overshoot: float = 0.1) -> Tween:
	if is_reduced():
		node.scale = Vector2.ONE
		node.modulate.a = 1.0
		return _immediate(node)
	return TweenFX.pop_in(node, duration, overshoot)


func fade_in(node: CanvasItem, duration: float = 0.5) -> Tween:
	if is_reduced():
		node.modulate.a = 1.0
		return _immediate(node)
	return TweenFX.fade_in(node, duration)


func fade_out(node: CanvasItem, duration: float = 0.5) -> Tween:
	if is_reduced():
		node.modulate.a = 0.0
		return _immediate(node)
	return TweenFX.fade_out(node, duration)


func shake(node: CanvasItem, duration: float = 0.3, amount: float = 10.0, shakes: int = 5) -> Tween:
	if is_reduced():
		return _immediate(node)
	return TweenFX.shake(node, duration, amount, shakes)


func hop(node: CanvasItem, duration: float = 0.4, height: float = 20.0) -> Tween:
	if is_reduced():
		return _immediate(node)
	return TweenFX.hop(node, duration, height)


func tada(node: CanvasItem, duration: float = 0.6) -> Tween:
	if is_reduced():
		node.scale = Vector2.ONE
		node.modulate.a = 1.0
		return _immediate(node)
	return TweenFX.tada(node, duration)


func upgrade(node: CanvasItem, duration: float = 0.8, glow: Color = Color(2.0, 1.8, 0.2, 1.0)) -> Tween:
	if is_reduced():
		node.scale = Vector2.ONE
		node.modulate.a = 1.0
		return _immediate(node)
	return TweenFX.upgrade(node, duration, glow)


func pulsate(node: CanvasItem, duration: float = 0.5, scale_factor: float = 1.2) -> Tween:
	if is_reduced():
		node.scale = Vector2.ONE
		return _immediate(node)
	return TweenFX.pulsate(node, duration, scale_factor)
