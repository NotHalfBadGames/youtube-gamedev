extends Node2D

signal reached_try_zone()
signal have_hit_wall()

var offset_step := 50
var moving := true
var hit_wall := false
var offset := 0.0
var burn_ammount = 0.0
var curve: Curve2D = null

func _process(delta: float) -> void:
	if hit_wall:
		$GodotIcon_svg.material.set_shader_parameter("progress", burn_ammount)
		burn_ammount += 0.01
	elif curve != null and moving:
		self.position = curve.sample_baked(offset)
		offset += offset_step*delta


func _on_area_2d_area_entered(area: Area2D) -> void:
	if hit_wall: return
	var body = area.get_parent() as TryZone
	if body == null:
		hit_wall = true
		have_hit_wall.emit()
	else:
		moving = false
		reached_try_zone.emit()
	
func _on_timer_timeout() -> void:
	#self.visible = false
	pass
	
func reset():
	
	#$GodotIcon_svg.material.set_shader_parameter("progress", 0.0)
	hit_wall = false
	curve = null
	moving = true
	$GodotIcon_svg.material.set_shader_parameter("progress", -1)
	offset = 0.0
	self.visible = true
