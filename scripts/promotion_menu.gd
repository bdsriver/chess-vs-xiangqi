extends ColorRect

signal promote_to(piece:String)


func _on_bishop_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		promote_to.emit('B')

func _on_queen_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		promote_to.emit('Q')

func _on_rook_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		promote_to.emit('R')

func _on_knight_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		promote_to.emit('N')


func _on_ready() -> void:
	promote_to.connect(get_parent().recv_promotion)
