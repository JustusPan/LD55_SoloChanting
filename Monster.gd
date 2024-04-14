extends CharacterBody2D
class_name Monster

@export var debug_name = "Monster"

# paras
@export var max_health = 100
@onready var health = max_health
@export var speed = 32.0
@export var damage = 10
@export var logic_interval = 0.5
@export var death_vfx:PackedScene
@export var target_update_interval = 0.5

var logic_timer: Timer
var damage_flash_duration = 0.05

@onready var hpBar = %HPBar
@onready var atkBox = %AtkBox
@onready var targetDetector = %OtherTargetDetector
@onready var zakoBDetector = %ZakoBDetector
@onready var ray_cast_2d = %RayCast2D


@onready var sprite := $Sprite2D

# for targeting system
var target = null
var target_timer: Timer
var stop_distance := 6.0
@onready var stop_distance_square = stop_distance * stop_distance

# guardian mode
@export var enable_guardian_mode = false
@export var guardian_distance = 32
@onready var guardian_distance_square = guardian_distance * guardian_distance
var init_deployment_position = Vector2.ZERO


func _ready():
	# record init deployment
	init_deployment_position = global_position
	
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
	target_timer.set_wait_time(target_update_interval)
	target_timer.set_one_shot(false)
	add_child(target_timer)
	target_timer.start()
	target_timer.connect("timeout", update_target) 
	
	# 此时可能tilemap都没准备好，不易碰撞检测？
	#if is_inside_tree():
		#await get_tree().physics_frame # wait for area ready?
		#await get_tree().physics_frame # wait for area ready?
		#update_target()


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
	# 1.优先级最高的ZakoB
	var zakoBs = zakoBDetector.get_overlapping_bodies()
	for body in zakoBs:
		towards_target(body)
		return
	
	# 获取所有重叠的Area2D
	var overlapping_bodies = targetDetector.get_overlapping_bodies()
	#var not_only_one = overlapping_bodies.size() > 1
	# 对每一个重叠的body进行处理
	for body in overlapping_bodies:
		if "debug_name" in body:
			if body.debug_name == "Player":
				towards_target(body)
				return
			if body.debug_name == "ZakoA":
				towards_target(body)
				return
		else:
			continue
			
	# 存在合法目标
	if target and is_instance_valid(target) and not target.is_queued_for_deletion() :
		# 更新
		towards_target(target)
		return
	
	# 只有非守卫模式才会去优先寻找玩家
	if not enable_guardian_mode:
		# find player
		if is_inside_tree():
			var players = get_tree().get_nodes_in_group("Player")  # 获得所有在"Player"组别里的节点
			# 检查是否找到了在"Player"组别里的节点，如果没有，那么直接返回
			if not players.is_empty():
				towards_target(players[0])
	else:
		recover_deployment()

func is_sight_block(targetObject:Node2D):
	ray_cast_2d.target_position = to_local(targetObject.global_position)
	ray_cast_2d.force_raycast_update()
	#queue_redraw()#debug_justus
	return ray_cast_2d.is_colliding()

#func _draw():
	#draw_line(Vector2.ZERO,ray_cast_2d.target_position,Color("#e800f2"),1.0)#debug_justus

func towards_target(t):
	if target != t and is_sight_block(t):
		#print_debug("target sight blocked!!!")
		return
	
	target = t
	#update direction
	var dir:Vector2 = target.global_position - self.global_position
	
	if enable_guardian_mode:
		var target_from_init = target.global_position - init_deployment_position
		if target_from_init.length_squared() > guardian_distance_square:
			velocity = Vector2.ZERO
			target = null
		else:
			if dir.length_squared() > stop_distance_square:
				velocity = dir.normalized() * speed
			else:
				velocity = Vector2.ZERO
	else:
		if dir.length_squared() > stop_distance_square:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2.ZERO

func recover_deployment():
	var dir = init_deployment_position - global_position
	if dir.length_squared() > stop_distance_square:
		velocity = dir.normalized() * speed * 0.5 # 回归部署点的速度是常规速度一半
	else:
		velocity = Vector2.ZERO

func get_damage(hp):
	if is_queued_for_deletion() or not is_instance_valid(self):
		pass
		
	# 开始一个新的Tween队列，让Sprite先变为红色，然后再变回原色
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.BLACK, 0.3 * damage_flash_duration) \
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
		.from(Color.BLACK).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	pass
