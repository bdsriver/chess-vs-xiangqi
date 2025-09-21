extends Node

const soldier_promotion_row = 5
const palace_rows:Array = [0,1,2]
const palace_cols:Array = [3,4,5]
const chess_pieces = ['P','B','R','N','Q','K']
#soldier, horse, elephant, cannon, general, advisor, rook
const xiangqi_pieces = ['s','h','e','c','g','a','r']

#return true if the chess player is in check. assume the chess player starts on rank 7-8
func chess_check(board:Array, row, col, move:Array) -> bool:
	var new:Array = new_board(board,row,col,move)
	var k_loc = [-1,-1]
	#find king location
	for i in range(9):
		for j in range(9):
			if new[i][j] == 'K':
				k_loc = [i,j]
	#check all chess pieces
	for i in range(9):
		for j in range(9):
			if new[i][j] in xiangqi_pieces:
				if attacks_square(new[i][j],i,j,k_loc,new):
					return true
		
	return false

func xiangqi_check(board:Array, row, col, move:Array) -> bool:
	var new:Array = new_board(board,row,col,move)
	var g_loc = [-1,-1]
	#find general location
	for i in range(9):
		for j in range(9):
			if new[i][j] == 'g':
				g_loc = [i,j]
	#check all xiangqi pieces
	for i in range(9):
		for j in range(9):
			if new[i][j] in chess_pieces:
				if attacks_square(new[i][j],i,j,g_loc,new):
					return true
	return false

#side should be 'Q' or 'K'
#only call if king and the castling rook have not moved
func can_castle(board, side:String) -> bool:
	#cannot castle if in check
	if chess_check(board, 8,5,[0,0]):
		return false
	match side:
		'K':
			if board[8][6] != ' ' or board[8][7] != ' ':
				return false 
			if board[8][5] != 'K' or board[8][8] != 'R':
				return false
			if chess_check(board,8,5,[0,1]):
				return false
			var new:Array = new_board(board,8,5,[0,2])
			if chess_check(new,8,8,[0,-2]):
				return false
		'Q':
			if board[8][4] != ' ' or board[8][3] != ' ' or board[8][2] != ' ' or board[8][1] != ' ':
				return false
			if board[8][5] != 'K' or board[8][0] != 'R':
				return false
			if chess_check(board,8,5,[0,-1]) or chess_check(board,8,5,[0,-2]):
				return false
			var new:Array = new_board(board,8,5,[0,-3])
			if chess_check(new,8,0,[0,3]):
				return false
	return true

func new_board(board:Array, row, col, move:Array) -> Array:
	var new:Array = []
	for i in range(9):
		new.append([])
		for j in range(9):
			new[i].append(board[i][j])
	var old_piece = new[row][col]
	new[row][col] = ' '
	new[row+move[0]][col+move[1]] = old_piece
	return new

#atker, atker row, atker col, attacked square
func attacks_square(p:String,row:int,col:int,atk_loc:Array,board:Array) -> bool:
	match p:
		'P':
			if row == atk_loc[0]-1 and (col == atk_loc[1]+1 or col == atk_loc[1]-1):
				return true
		'K':
			var v_dist = row - atk_loc[0]
			var h_dist = col - atk_loc[1]
			if h_dist > -2 and h_dist < 2 and v_dist > -2 and v_dist < -2:
				return true
		'B':
			var direction_matrix:Array = [[1,1],[-1,1],[1,-1],[-1,-1]]
			return check_vector(direction_matrix,row,col,atk_loc,board)
		'R':
			var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
			return check_vector(direction_matrix,row,col,atk_loc,board)
		'Q':
			var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]
			return check_vector(direction_matrix,row,col,atk_loc,board)
		'N':
			var move_matrix:Array = [[2,1],[2,-1],[1,2],[1,-2],[-1,2],[-1,-2],[-2,1],[-2,-1]]
			for m in move_matrix:
				if row+m[0] == atk_loc[0] and row+m[1] == atk_loc[1]:
					return true
		'r':
			var direction_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
			return check_vector(direction_matrix,row,col,atk_loc,board)
		's': #TODO: change this if river location changes
			if row >= soldier_promotion_row and row == atk_loc[0] and (col == atk_loc[1]+1 or col ==atk_loc[1]-1):
				return true
			if row == atk_loc[0]-1 and col == atk_loc[1]:
				return true
		'c':
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
					elif jumped and board[r][c] in xiangqi_pieces:
						can_keep_going = false
					elif jumped and board[r][c] in chess_pieces:
						if r == atk_loc[0] and c == atk_loc[1]:
							return true
						can_keep_going = false
		'e':
			var move_matrix:Array = [[2,2],[-2,2],[2,-2],[-2,-2]]
			for m in move_matrix:
				if board[row+m[0]/2][col+m[1]/2] != ' ':
					continue
				if row+m[0] == atk_loc[0] and col+m[1] == atk_loc[1]:
					return true
		'g':
			var move_matrix:Array = [[1,0],[-1,0],[0,1],[0,-1]]
			for m in move_matrix:
				if row+m[0] not in palace_rows or col+m[1] not in palace_cols:
					continue
				if row+m[0] == atk_loc[0] and col+m[1] == atk_loc[1]:
					return true
		'a':
			var move_matrix:Array = [[1,1],[-1,1],[1,-1],[-1,-1]]
			for m in move_matrix:
				if row+m[0] not in palace_rows or col+m[1] not in palace_cols:
					continue
				if row+m[0] == atk_loc[0] and col+m[1] == atk_loc[1]:
					return true
		'h':
			var move_matrix:Array = [[2,1],[2,-1],[1,2],[1,-2],[-1,2],[-1,-2],[-2,1],[-2,-1]]
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
				if row+m[0] == atk_loc[0] and col+m[1] == atk_loc[1]:
					return true
	return false

func check_vector(direction_matrix:Array, row, col, atk_loc,board):
	for d in direction_matrix:
		var r = row
		var c = col
		var can_keep_going:bool = true
		while can_keep_going:
			r+=d[0]
			c+=d[1]
			if r>8 or r<0 or c>8 or c<0:
				can_keep_going = false
			elif board[r][c] != ' ':
				can_keep_going = false
			if r == atk_loc[0] and c ==atk_loc[1]:
				return true
	return false
