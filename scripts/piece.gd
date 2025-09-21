class_name Piece
extends TextureRect

@export var funcs: piece_func
@export var fen_char: String
@export var col: int
@export var row: int

func _ready() -> void:
	self.texture = funcs.texture
	fen_char = funcs.fen_char
