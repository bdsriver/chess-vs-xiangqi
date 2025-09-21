extends Node2D

signal promote_to(piece:String)

const BOARD_SIZE = 9
const sq_size = 100
const chess_pawn_start_rank = 7
const chess_pieces = ['P','B','R','N','Q','K']
#soldier, horse, elephant, cannon, general, advisor, rook
const xiangqi_pieces = ['s','h','e','c','g','a','r']
const palace_rows:Array = [0,1,2]
const palace_cols:Array = [3,4,5]
const soldier_promotion_row:int = 5
const pawn_promotion_row:int = 0

const outline = preload("res://Assets/purple-outline.png")
const piece_temp:PackedScene = preload("res://scenes/piece.tscn")
const C_BISHOP = preload("res://Resources/c_bishop.tres")
const C_KING = preload("res://Resources/c_king.tres")
const C_KNIGHT = preload("res://Resources/c_knight.tres")
const C_PAWN = preload("res://Resources/c_pawn.tres")
const C_QUEEN = preload("res://Resources/c_queen.tres")
const C_ROOK = preload("res://Resources/c_rook.tres")
const X_ADVISOR = preload("res://Resources/x_advisor.tres")
const X_CANNON = preload("res://Resources/x_cannon.tres")
const X_ELEPHANT = preload("res://Resources/x_elephant.tres")
const X_GENERAL = preload("res://Resources/x_general.tres")
const X_HORSE = preload("res://Resources/x_horse.tres")
const X_ROOK = preload("res://Resources/x_rook.tres")
const X_SOLDIER = preload("res://Resources/x_soldier.tres")

@onready var board = []
@onready var pieces = $Pieces
@onready var moves = $moves
@onready var check = $Check
@onready var promotion_menu = $"Promotion Menu"
@onready var curr_fen = 'rheagaehr/9/1c5c1/s1s1s1s1s/9/9/9/PPPPPPPPP/R1NBQKBNR' #TODO: see if this can be constant
@onready var selected_piece_loc = [-1,-1]
@onready var chess_player_turn:bool = true
@onready var castle_qside = true
@onready var castle_kside = true
@onready var autopromote = false
@onready var promoting = false

func _on_ready() -> void:
	#init board array
	for i in range(9):
		board.append([])
		for j in range(9):
			board[i].append(' ')
	display_fen(curr_fen)


func display_fen(fen: String) -> void:
	var row: int = 0
	var col: int = 0
	for char in fen:
		if char == ' ':
			break
		if char.is_valid_int():
			col += int(char)
		else:
			if char != '/':
				place_piece(row, col, char)
				col += 1
			else:
				col = 0
				row += 1
			

func place_piece(row:int,col:int, p:String) -> void:
	board[row][col] = p
	var piece: TextureRect = piece_temp.instantiate()
	piece.custom_minimum_size = Vector2(80,80)
	match p:
		'B':
			piece.funcs = C_BISHOP
		'K':
			piece.funcs = C_KING
			piece.custom_minimum_size = Vector2(70,70)
		'N':
			piece.funcs = C_KNIGHT
		'P':
			piece.funcs = C_PAWN
		'Q':
			piece.funcs = C_QUEEN
			piece.custom_minimum_size = Vector2(69,69)
		'R':
			piece.funcs = C_ROOK
		'a':
			piece.funcs = X_ADVISOR
		'c':
			piece.funcs = X_CANNON
		'e':
			piece.funcs = X_ELEPHANT
		'g':
			piece.funcs = X_GENERAL
			piece.custom_minimum_size = Vector2(70,70)
		'h':
			piece.funcs = X_HORSE
		'r':
			piece.funcs = X_ROOK
		's':
			piece.funcs = X_SOLDIER
	piece.position = Vector2(col*sq_size+12, row*sq_size+12)
	piece.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	piece.gui_input.connect(on_piece_clicked)
	pieces.add_child(piece)
	piece.col = col
	piece.row = row

	
func on_piece_clicked(event:InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		#do not do this if we are waiting on a promotion pick
		if promoting:
			return
		var col = snapped(get_global_mouse_position().x, 0) / sq_size
		var row = snapped(get_global_mouse_position().y, 0) / sq_size
		print(board[row][col])
		print(row,col)
		#only do this if it is the piece's turn
		var p = board[row][col]
		if p in chess_pieces and chess_player_turn:
			selected_piece_loc = [row,col]
			display_moves(row,col)
		elif p in xiangqi_pieces and not chess_player_turn:
			selected_piece_loc = [row,col]
			display_moves(row,col)

func remove_piece(row, col) -> void:
	board[row][col] = ' '
	#find the piece at that square
	for piece in pieces.get_children():
		if piece.col == col and piece.row == row:
			piece.queue_free()
			return

func recv_promotion(piece:String) -> void:
	promoting = false
	promotion_menu.visible = false
	#find the promoting pawn
	var row = 0
	var col = -1
	for i in range(9):
		if board[row][i] == 'P':
			col = i
	remove_piece(row,col)
	place_piece(row,col,piece)

func display_moves(row,col) -> void:
	#remove already displayed moves
	for m in moves.get_children():
		moves.remove_child(m)
		m.queue_free()
	var p:String = board[row][col]
	match p:
		'P':
			pawn_display(row,col)
		'N':
			knight_display(row,col)
		'R':
			rook_display(row,col,p)
		'B':
			bishop_display(row,col)
		'Q':
			queen_display(row,col)
		'K':
			king_display(row,col)
		'r':
			rook_display(row,col,p)
		'a':
			advisor_display(row,col)
		's':
			soldier_display(row,col)
		'e':
			elephant_display(row,col)
		'g':
			general_display(row,col)
		'h':
			horse_display(row,col)
		'c':
			cannon_display(row,col)

func indicate_square(row,col) -> void:
	var move:TextureRect = TextureRect.new()
	move.texture = outline
	move.custom_minimum_size = Vector2(sq_size,sq_size)
	move.position = Vector2(col*sq_size, row*sq_size)
	move.gui_input.connect(on_move_clicked)
	moves.add_child(move)

func on_move_clicked(event:InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		#change the turn player
		chess_player_turn = not chess_player_turn
		var p:String = board[selected_piece_loc[0]][selected_piece_loc[1]]
		remove_piece(selected_piece_loc[0],selected_piece_loc[1])
		#remove all move options
		for m in moves.get_children():
			moves.remove_child(m)
			m.queue_free()
		var col = snapped(get_global_mouse_position().x, 0) / sq_size
		var row = snapped(get_global_mouse_position().y, 0) / sq_size
		#remove piece at the location if it is there
		if board[row][col] != ' ':
			remove_piece(row,col)
		place_piece(row,col,p)
		#castling
		if p == 'K':
			castle_kside = false
			castle_qside = false
			if selected_piece_loc == [8,5] and row == 8 and col == 7:
				remove_piece(8,8)
				place_piece(8,6,'R')
			if selected_piece_loc == [8,5] and row == 8 and col == 2:
				remove_piece(8,0)
				place_piece(8,3,'R')
		if p == 'R' and row == 8 and col == 8:
			castle_kside = false
		if p == 'R' and row == 8 and col == 0:
			castle_qside = false
		if p == 'P' and row == pawn_promotion_row:
			promotion_menu.visible = true
			promoting = true
		#check for checkmate/stalemate #TODO: send this to the next screen
		if not has_legal_move():
			if chess_player_turn:
				if check.chess_check(board,row,col,[0,0]):
					print('checkmate')
				else:
					print('stalemate')
			else:
				print('checkmate or stalemate')
			#restart
			get_tree().change_scene_to_file("res://scenes/board.tscn")
		
func has_legal_move() -> bool:
	if not chess_player_turn:
		for i in range(9):
			for j in range(9):
				if board[i][j] in xiangqi_pieces:
					match board[i][j]:
						'r':
							if rook_display(i,j,board[i][j],true):
								return true
						'h':
							if horse_display(i,j,true):
								return true
						'e':
							if elephant_display(i,j,true):
								return true
						'a':
							if advisor_display(i,j,true):
								return true
						'g':
							if general_display(i,j,true):
								return true
						'c':
							if cannon_display(i,j,true):
								return true
						's':
							if soldier_display(i,j,true):
								return true
	else:
		for i in range(9):
			for j in range(9):
				if board[i][j] in chess_pieces:
					match board[i][j]:
						'R':
							if rook_display(i,j,'R',true):
								return true
						'N':
							if knight_display(i,j,true):
								return true
						'B':
							if bishop_display(i,j,true):
								return true
						'Q':
							if queen_display(i,j,true):
								return true
						'K':
							if king_display(i,j,true):
								return true
						'P':
							if pawn_display(i,j,true):
								return true
	return false

#TODO: Modify all pieces to change behavior based on color
func pawn_display(row,col,non_display:bool = false) -> bool:
	if board[row-1][col] == ' ' and row > 0:
		if not check.chess_check(board,row,col,[-1,0]):
			if non_display:
				return true
			indicate_square(row-1,col)
		if row == chess_pawn_start_rank and board[row-2][col] == ' 'and not check.chess_check(board,row,col,[-2,0]):
			if non_display:
				return true
			indicate_square(row-2,col)
	if col > 0 and board[row-1][col-1] in xiangqi_pieces and not check.chess_check(board,row,col,[-1,-1]):
		if non_display:
			return true
		indicate_square(row-1,col-1)
	if col < 8 and board[row-1][col+1] in xiangqi_pieces and not check.chess_check(board,row,col,[-1,1]):
		if non_display:
			return true
		indicate_square(row-1,col+1)
	return false

func knight_display(row,col,non_display:bool = false) -> bool:
	var move_matrix:Array = [[2,1],[2,-1],[1,2],[1,-2],[-1,2],[-1,-2],[-2,1],[-2,-1]]
	for m in move_matrix:
		if row+m[0] > 8 or col+m[1] > 8 or row+m[0] < 0 or col+m[1] < 0:
			continue
		if board[row+m[0]][col+m[1]] in chess_pieces:
			continue
		if not check.chess_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	return false

func rook_display(row,col,piece,non_display:bool = false) -> bool:
	var enemies = []
	if piece == 'R':
		enemies = xiangqi_pieces
	else:
		enemies = chess_pieces
	var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
	for d in direction_matrix:
		var r = row
		var c = col
		var can_keep_going:bool = true
		while can_keep_going:
			r+=d[0]
			c+=d[1]
			if r>8 or r<0 or c>8 or c<0:
				can_keep_going = false
			elif board[r][c] in enemies:
				if piece == 'R' and not check.chess_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
				if piece == 'r' and not check.xiangqi_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
				can_keep_going = false
			elif board[r][c] != ' ':
				can_keep_going = false
			if can_keep_going and piece == 'R' and not check.chess_check(board,row,col,[r-row,c-col]):
				if non_display:
					return true
				indicate_square(r,c)
			if can_keep_going and piece == 'r' and not check.xiangqi_check(board,row,col,[r-row,c-col]):
				if non_display:
					return true
				indicate_square(r,c)
	return false

func bishop_display(row,col,non_display:bool = false) -> bool:
	var direction_matrix:Array = [[1,1],[-1,1],[1,-1],[-1,-1]]
	for d in direction_matrix:
		var r = row
		var c = col
		var can_keep_going:bool = true
		while can_keep_going:
			r+=d[0]
			c+=d[1]
			if r>8 or r<0 or c>8 or c<0:
				can_keep_going = false
			elif board[r][c] in chess_pieces:
				can_keep_going = false
			elif board[r][c] in xiangqi_pieces:
				if not check.chess_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
				can_keep_going = false
			if can_keep_going:
				if not check.chess_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
	return false

func queen_display(row,col,non_display:bool = false) -> bool:
	var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]
	for d in direction_matrix:
		var r = row
		var c = col
		var can_keep_going:bool = true
		while can_keep_going:
			r+=d[0]
			c+=d[1]
			if r>8 or r<0 or c>8 or c<0:
				can_keep_going = false
			elif board[r][c] in chess_pieces:
				can_keep_going = false
			elif board[r][c] in xiangqi_pieces:
				if not check.chess_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
				can_keep_going = false
			if can_keep_going:
				if not check.chess_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
	return false

func king_display(row,col,non_display:bool = false) -> bool:
	var move_matrix:Array = [[1,1],[1,-1],[1,0],[0,-1],[0,1],[-1,1],[-1,0],[-1,-1]]
	for m in move_matrix:
		if row+m[0] > 8 or col+m[1] > 8 or row+m[0] < 0 or col+m[1] < 0:
			continue
		if board[row+m[0]][col+m[1]] in chess_pieces:
			continue
		if not check.chess_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	if castle_kside and check.can_castle(board, 'K'):
		if non_display:
			return true
		indicate_square(8,7)
	if castle_qside and check.can_castle(board, 'Q'):
		if non_display:
			return true
		indicate_square(8,2)
	return false
	
func advisor_display(row,col,non_display:bool = false) -> bool:
	var move_matrix:Array = [[1,1],[-1,1],[1,-1],[-1,-1]]
	for m in move_matrix:
		if row+m[0] not in palace_rows or col+m[1] not in palace_cols:
			continue
		if board[row+m[0]][col+m[1]] in xiangqi_pieces:
			continue
		if not check.xiangqi_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	return false

func soldier_display(row,col,non_display:bool = false) -> bool:
	if row >= soldier_promotion_row:
		if col != 0 and not check.xiangqi_check(board,row,col,[0,-1]):
			if non_display:
				return true
			indicate_square(row,col-1)
		if col != 8 and not check.xiangqi_check(board,row,col,[0,1]):
			if non_display:
				return true
			indicate_square(row,col+1)
	if row!= 8 and not check.xiangqi_check(board,row,col,[1,0]):
		if non_display:
			return true
		indicate_square(row+1,col)
	return false

func elephant_display(row,col,non_display:bool = false) -> bool:
	var move_matrix:Array = [[2,2],[-2,2],[2,-2],[-2,-2]]
	for m in move_matrix:
		if row+m[0] < 0 or row+m[0] >= soldier_promotion_row or col+m[1] > 8 or col+m[1] < 0:
			continue
		if board[row+m[0]][col+m[1]] in xiangqi_pieces or board[row+m[0]/2][col+m[1]/2] != ' ':
			continue
		if not check.xiangqi_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	return false

func general_display(row,col,non_display:bool = false) -> bool:
	var move_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
	for m in move_matrix:
		if row+m[0] not in palace_rows or col+m[1] not in palace_cols:
			continue
		if board[row+m[0]][col+m[1]] in xiangqi_pieces:
			continue
		if not check.xiangqi_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	return false

func horse_display(row,col,non_display:bool = false) -> bool:
	#if there is nothing blocking this would be the matrix
	var move_matrix:Array = [[2,1],[2,-1],[1,2],[-1,2],[-1,-2],[1,-2],[-2,1],[-2,-1]]
	#remove the squares it cant jump to
	if row < 8 and board[row+1][col] != ' ':
		move_matrix.erase([2,1])
		move_matrix.erase([2,-1])
	if col < 8 and board[row][col+1] != ' ':
		move_matrix.erase([1,2])
		move_matrix.erase([-1,2])
	if col < 8 and board[row][col-1] != ' ':
		move_matrix.erase([1,-2])
		move_matrix.erase([-1,-2])
	if row > 0 and board[row-1][col] != ' ':
		move_matrix.erase([-2,1])
		move_matrix.erase([-2,-1])
	for m in move_matrix:
		if row+m[0] > 8 or col+m[1] > 8 or row+m[0] < 0 or col+m[1] < 0:
			continue
		if board[row+m[0]][col+m[1]] in xiangqi_pieces:
			continue
		if not check.xiangqi_check(board,row,col,m):
			if non_display:
				return true
			indicate_square(row+m[0],col+m[1])
	return false

func cannon_display(row,col,non_display:bool = false) -> bool:
	var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
	for d in direction_matrix:
		var r = row
		var c = col
		var can_keep_going:bool = true
		var jumped:bool = false
		while can_keep_going:
			r+=d[0]
			c+=d[1]
			if r>8 or r<0 or c>8 or c<0:
				can_keep_going = false
			elif not jumped and board[r][c] != ' ':
				jumped = true
				continue
			elif jumped and board[r][c] in xiangqi_pieces:
				can_keep_going = false
			elif jumped and board[r][c] in chess_pieces:
				can_keep_going = false
				if not check.xiangqi_check(board,row,col,[r-row,c-col]):
					if non_display:
						return true
					indicate_square(r,c)
			elif jumped and board[r][c] == ' ':
				continue
			if can_keep_going and not check.xiangqi_check(board,row,col,[r-row,c-col]):
				if non_display:
					return true
				indicate_square(r,c)
	return false
