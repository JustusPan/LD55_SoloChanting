extends StaticBody2D
class_name Door

enum DoorTypes
{
	NORMAL,
	LOCK_YELLOW,
	LOCK_BLUE,
	LOCK_RED,
}
@export var door_type = DoorTypes.NORMAL
@export var door_open_vfx: PackedScene

func open():
	if door_open_vfx:
		var vfx = door_open_vfx.instantiate()
		vfx.global_position = global_position
		add_sibling(vfx)
		vfx.emitting = true
	
	queue_free()
	pass
