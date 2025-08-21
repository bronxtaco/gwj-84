extends Node2D

var enabled := false
var draw_objects = []

func _ready() -> void:
	Events.draw_debug_vector_arrow.connect(_on_draw_debug_vector_arrow)
	
	visible = enabled

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_f2"):
		Global.cheater = true
		enabled = !enabled
		visible = enabled
	
	if !enabled:
		return
	queue_redraw()

func _draw():
	# Example usage:
	var count = draw_objects.size()
	for i in range(count):
		var o = draw_objects.pop_back()
		draw_vector_arrow_2d(o.start_pos, o.vector, o.color, o.thickness, o.arrow_size)
		

# 2D Vector Arrow Drawing
func draw_vector_arrow_2d(start_pos: Vector2, vector: Vector2, color: Color = Color.RED, thickness: float = 2.0, arrow_size: float = 10.0):
	if !enabled:
		return
	
	var end_pos = start_pos + vector
	
	# Draw the main line
	draw_line(start_pos, end_pos, color, thickness)
	
	# Calculate arrow head
	var arrow_length = arrow_size
	var arrow_angle = PI / 6  # 30 degrees
	
	if vector.length() > 0:
		var direction = vector.normalized()
		var perp = Vector2(-direction.y, direction.x)
		
		# Arrow head points
		var arrow_tip1 = end_pos - direction * arrow_length + perp * arrow_length * 0.5
		var arrow_tip2 = end_pos - direction * arrow_length - perp * arrow_length * 0.5
		
		# Draw arrow head
		draw_line(end_pos, arrow_tip1, color, thickness)
		draw_line(end_pos, arrow_tip2, color, thickness)


func _on_draw_debug_vector_arrow(start_pos: Vector2, vector: Vector2, color: Color = Color.RED, thickness: float = 2.0, arrow_size: float = 10.0):
	draw_objects.push_back({
		"start_pos": start_pos,
		"vector": vector,
		"color": color,
		"thickness": thickness,
		"arrow_size": arrow_size,
	})
