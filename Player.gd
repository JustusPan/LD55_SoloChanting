extends CharacterBody2D
class_name Player

signal picked_item(item_type,count)
signal door_interacted(door, door_type)
signal died()

@export var debug_name = "Player"

@export var max_health = 100
@onready var health = max_health

@export var speed: float = 96.0
@export var slowdown_speed_scale = 0.5
var cur_speed_scale = 1.0

@onready var hpBar := %HPBar
@onready var sprite := $Sprite2D
@onready var interact_area = %InteractArea
@onready var slowdown_timer = %SlowdownTimer # getting hurt will be slowed down


var damage_flash_duration = 0.05


# Called when the node enters the scene tree for the first time.
func _ready():
	# update UI
	hpBar.visible = false
	hpBar.min_value = 0
	hpBar.max_value = max_health
	hpBar.value = health
	
	cur_speed_scale = 1.0
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	pass

func _physics_process(_delta):
	var x_input = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	var y_input = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	velocity = Vector2(x_input, y_input).normalized() * speed * cur_speed_scale
	
	# 仅当需要翻转时才改变scale
	if velocity.x > 0:
		if sprite.scale.x < 0:
			sprite.scale.x *= -1
	elif velocity.x < 0:
		if sprite.scale.x > 0:
			sprite.scale.x *= -1
	
	# move the player
	move_and_slide()
	
func get_damage(hp):
	# 开始一个新的Tween队列，让Sprite先变为红色，然后再变回原色
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.3 * damage_flash_duration) \
		.from(Color(1, 1, 1)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(recover_vfx).set_delay(damage_flash_duration)
	health -= hp
	
	# update HPBar
	if not hpBar.visible:
		hpBar.visible = true
	hpBar.value = health
	
	cur_speed_scale = slowdown_speed_scale
	slowdown_timer.start()
	
	#print(str(debug_name) + " dinjured!" + str(hp)) #debug_justus
	if health <= 0:
		health = 0
		hpBar.value = health
		#print("Player died!") #debug_justus
		emit_signal("died")
		queue_free() # 临时处理
	pass

func recover_vfx():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), damage_flash_duration) \
		.from(Color.RED).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	pass


func _on_interact_area_body_entered(body):
	if not body or body.is_queued_for_deletion():
		pass
		
	if "item_type" in body:
		emit_signal("picked_item",body.item_type,body.count)
		body.queue_free()
		
	if "door_type" in body:
		emit_signal("door_interacted",body,body.door_type)


func _on_slowdown_timer_timeout():
	# recover speed 
	cur_speed_scale = 1.0
	pass # Replace with function body.
