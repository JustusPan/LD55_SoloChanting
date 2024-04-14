
extends CharacterBody2D

@export var debug_name = "ZakoX"

# paras
enum ZakoTypes {ZakoA,ZakoB,ZakoC}
@export var type = ZakoTypes.ZakoA
@export var max_health = 100
@onready var health = max_health
@export var speed = 32.0
@export var damage = 10
@export var logic_interval = 0.5
@export var death_vfx:PackedScene

var logic_timer: Timer
var damage_flash_duration = 0.05

@onready var hpBar = %HPBar
@onready var atkBox := %AtkBox
@onready var targetDetector := %TargetDetector

@onready var sprite := $Sprite2D

# for targeting system
var target = null
var target_timer: Timer
var stop_distance := 6.0
@onready var stop_distance_square = stop_distance * stop_distance


# draw parameters
@export var draw_radius = 16.0 # 半径
@export var draw_color:Color = Color.WHITE
@export var enable_draw_hint := false


func _ready():
	# update UI
	hpBar.visible = false
	hpBar.min_value = 0
	hpBar.max_value = max_health
	hpBar.value = health
	
	# 创建一个计时器，设定间隔和循环模式
	logic_timer = Timer.new()
	logic_timer.set_wait_time(logic_interval)
	logic_timer.set_one_shot(false)
	add_child(logic_timer)
	logic_timer.start()
	# 将计时器超时的信号与伤害函数连接起来
	logic_timer.connect("timeout", update_logic)
	
	## 负责更新移动方向的计时器
	target_timer = Timer.new()
	target_timer.set_wait_time(0.5)
	target_timer.set_one_shot(false)
	add_child(target_timer)
	target_timer.start()
	target_timer.connect("timeout", update_target) 
	
	
	await get_tree().physics_frame # wait for area ready?
	await get_tree().physics_frame # wait for area ready?
	call_deferred("update_target")
	#update_target()
	
	queue_redraw()
	
func _process(_delta):
	queue_redraw()

func _physics_process(_delta):
	move_and_slide()

func update_logic():
	apply_damage()

# 每个logic_interval都检查是否有对象处于重叠状态
func apply_damage():
	# 获取所有重叠的Area2D
	var overlapping_bodies = atkBox.get_overlapping_bodies()

	# 对每一个重叠的body进行处理
	for body in overlapping_bodies:
		if body.has_method("get_damage"):
			body.get_damage(damage)

func update_target():
	#print_debug("enter update_target")
	# 存在合法目标
	if target and is_instance_valid(target) and not target.is_queued_for_deletion():
		# 更新
		towards_target(target)
		return
		
	var monsters = targetDetector.get_overlapping_bodies()
	if monsters.size() > 0:
		# random pick
		var index = randi() % monsters.size()
		var random_element = monsters[index]
		towards_target(random_element)
		return
		
	# 存在合法目标
	if target and is_instance_valid(target) and not target.is_queued_for_deletion():
		return
	else:
		# 无目标
		velocity = Vector2.ZERO
		

func towards_target(t):
	target = t
	#update direction
	var dir:Vector2 = target.global_position - self.global_position
	
	if dir.length_squared() > stop_distance_square:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO
	pass

func get_damage(hp):
	if is_queued_for_deletion() or not is_instance_valid(self):
		pass
		
	# 开始一个新的Tween队列，让Sprite先变为红色，然后再变回原色
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.3 * damage_flash_duration) \
		.from(Color(1, 1, 1)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(recover_vfx).set_delay(damage_flash_duration)
	health -= hp
	$HurtSFX.playing = true
	
	# update HPBar
	if not hpBar.visible:
		hpBar.visible = true
	hpBar.value = health
	
	#print(str(debug_name) + " dinjured!" + str(hp)) #debug_justus
	if health <= 0:
		health = 0
		hpBar.value = health
		gen_death_vfx()
		#print(str(debug_name) + " died!") #debug_justus
		queue_free()
	pass
	
func gen_death_vfx():
	if not death_vfx:
		return
	var vfx:CPUParticles2D = death_vfx.instantiate()
	vfx.global_position = global_position
	add_sibling(vfx)
	vfx.emitting = true
	pass
	
func recover_vfx():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), damage_flash_duration) \
		.from(Color.RED).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	pass

func _draw():
	if not enable_draw_hint:
		return 
	

	if target and is_instance_valid(target) and not target.is_queued_for_deletion():
		if type == ZakoTypes.ZakoC:
			draw_line(Vector2.ZERO,target.global_position - global_position,Color("#e800f2"),1.0)
		else:
			custom_draw_circle()
	else:
		custom_draw_circle()
		
func custom_draw_circle():
	var center = Vector2.ZERO # 圆心
	var start_angle = 0.0 # 起始角度
	var end_angle = deg_to_rad(360.0) # 终止角度
	var width = 0.3 # 圆环的宽度
	var detail = 24
	# 这里将圆环绘制成了四分之三个圆
	draw_arc(center, draw_radius, start_angle, end_angle, detail, draw_color, width)

func _on_close_body_detector_body_entered(body):
	if type == ZakoTypes.ZakoC:
		if body.has_method("get_damage"):
			var cause_damage = body.max_health if body.max_health < 3001 else 3000
			body.get_damage(cause_damage) #必杀直接目标
			apply_damage() #对周围目标造成大量伤害
			self.get_damage(health * 1.1) # suicide
	pass # Replace with function body.
