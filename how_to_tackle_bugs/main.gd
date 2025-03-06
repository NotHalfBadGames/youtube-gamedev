extends Node2D

const ANCHORPOINT = preload("res://anchor_point.tscn")
const INITAL_TIME = 5.0

var is_finished := false:
	set(finish):
		is_finished = finish
		_line.visible = not is_finished
		_the_anchor_points.visible = not is_finished
		if is_finished:
			_instruction_label.text = "r - replay"
		else:
			_instruction_label.text = "e - toggle draw/edit\nleft click - add point"

var is_drawing := true
var is_moving := false

var _curve = Curve2D.new()
var _anchor_points: Array[AnchorPoint] = []
var countdown_timer := 5.0:
	set(new_time):
		countdown_timer = new_time
		if not is_moving:
			_state_label.text = "Little Buddy Moving In: " + str(int(countdown_timer)) 
		else:
			_state_label.text = "Time Left: " + str(int(countdown_timer)) 
			
var _inital_little_buddy_position := Vector2.INF

@onready var _line = $Line2D
@onready var _little_buddy = $LittleBuddy
@onready var _state_label = $CanvasLayer/VBoxContainer/StateLabel
@onready var _instruction_label = $CanvasLayer/VBoxContainer/InstructionLabel
@onready var _the_anchor_points = $TheAnchorPoints

func _ready() -> void:
	_add_anchor_point(_little_buddy.position)
	_little_buddy.reached_try_zone.connect(_on_reached_try_zone)
	_little_buddy.have_hit_wall.connect(_on_have_hit_wall)
	_inital_little_buddy_position = _little_buddy.position

func _process(delta: float) -> void:
	if is_finished: 
		if Input.is_action_just_pressed("reset"):
			_reset_game()
		return
	countdown_timer = max(countdown_timer-delta,0.0)
	
	if countdown_timer == 0.0:
		if _handle_no_line(): return
		is_moving = true
		countdown_timer = 30.0
	elif is_moving:
		_bake_curve()
		
	if Input.is_action_just_pressed("toggle_edit"):
		is_drawing = not is_drawing
		
func _unhandled_input(event: InputEvent) -> void:
	#if not event.is_action("left_click"): return #CRASH!
	if not event.is_action_pressed("left_click"): return #no crash!
	
	if is_drawing:
		_on_drawing(event)
	else:
		_on_edit(event)
		
func _on_drawing(event: InputEvent):
	var position = get_global_mouse_position()
	_add_anchor_point(position)
	
func _add_anchor_point(position: Vector2, index := -1):
	var new_anchor_point = ANCHORPOINT.instantiate() as AnchorPoint
	_anchor_points.insert(index,new_anchor_point)
	_line.add_point(position,index)
	new_anchor_point.position = position
	_the_anchor_points.add_child(new_anchor_point)
		
func _on_edit(event: InputEvent):
	var position = get_global_mouse_position()
	
	_curve.clear_points()
	
	var closest_distance = INF
	var closest_point = Vector2.INF
	var closest_segment = -1
	
	for i in range(_line.get_point_count()-1):
		_curve.add_point(_line.points[i])
		_curve.add_point(_line.points[i+1])
		
		#another way to prevent crash:
		#if is_zero_approx(_curve.get_baked_length()):
		#	_curve.clear_points()
		#	continue
		var current_closest_t = _curve.get_closest_point(position)
		var current_offset = _curve.get_closest_offset(current_closest_t)
		var current_closest_point = _curve.sample_baked(current_offset)
		var current_current_distance = position.distance_to(current_closest_point)
		
		if current_current_distance < closest_distance:
			closest_distance = current_current_distance
			closest_point = current_closest_point
			closest_segment = i
			
		_curve.clear_points()
			
	if closest_distance < _line.width/2:
		_add_anchor_point(position,closest_segment+1)
		
func _bake_curve():
	_curve.clear_points()
	for pos in _line.points:
		_curve.add_point(pos)
	_little_buddy.curve = _curve
	
func _handle_no_line():
	if _line.get_point_count() < 2:
		is_finished = true
		_state_label.text = "You have to move...\nor else I will light you on fire."
		_little_buddy.hit_wall = true
		return true
	return false
	
func _on_reached_try_zone():
	countdown_timer = -1
	_state_label.text = "You win... this time."
	is_finished = true
	
func _on_have_hit_wall():
	countdown_timer = -1
	_state_label.text = "Goodbye."
	is_finished = true
	
func _reset_game():
	countdown_timer = 5.0
	is_moving = false
	is_drawing = true
	is_finished = false
	_little_buddy.position = _inital_little_buddy_position
	_line.clear_points() 
	_the_anchor_points.queue_free()
	_the_anchor_points = Node2D.new()
