extends Node2D

@export var ZakoAPrefab: PackedScene
@export var ZakoBPrefab: PackedScene
@export var ZakoCPrefab: PackedScene
@export var MonsterPrefab: PackedScene

@onready var fps_label = %LabelFPS

@export var init_zakoA_slots = 10
@export var init_zakoB_slots = 3
@export var init_zakoC_slots = 2
@onready var cur_zakoA_slots = init_zakoA_slots
@onready var cur_zakoB_slots = init_zakoB_slots
@onready var cur_zakoC_slots = init_zakoC_slots

@export var init_key_yellow = 0
@export var init_key_blue = 0
@export var init_key_red = 0
@onready var cur_key_yellow = init_key_yellow
@onready var cur_key_blue = init_key_blue
@onready var cur_key_red = init_key_red


@onready var label_zako_a = %LabelZakoA
@onready var label_zako_b = %LabelZakoB
@onready var label_zako_c = %LabelZakoC
@onready var label_key_yellow = %LabelKeyYellow
@onready var label_key_blue = %LabelKeyBlue
@onready var label_key_red = %LabelKeyRed

@onready var win_anim_player = $HUD/GUI/WinInfo/AnimationPlayer
var has_wined = false
@onready var title_anim_player = $HUD/GUI/TitleInfo/AnimationPlayer
@onready var died_anim_player = $HUD/GUI/DiedInfo/AnimationPlayer



var player
var level_root
var final_root

const CLICK_PARTICLE = preload("res://static_assets/click_particle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	title_anim_player.play("play")
	refresh_gui()
	
	# find player
	var players = get_tree().get_nodes_in_group("Player")  # 获得所有在"Player"组别里的节点
	# 检查是否找到了在"Player"组别里的节点，如果没有，那么直接返回
	if not players.is_empty():
		player = players[0]
		if not player.is_connected("picked_item",_on_player_picked_item):
			player.connect("picked_item",_on_player_picked_item)
		if not player.is_connected("door_interacted",_on_door_interacted):
			player.connect("door_interacted",_on_door_interacted)
		if not player.is_connected("died",_on_player_died):
			player.connect("died",_on_player_died)
			
	# find level root
	var roots = get_tree().get_nodes_in_group("LevelRoot")
	if not roots.is_empty():
		level_root = roots[0]
		
	# find final root
	var final_roots = get_tree().get_nodes_in_group("FinalRoot")
	if not final_roots.is_empty():
		final_root = final_roots[0]
	pass # Replace with function body.

func _unhandled_input(event):
	# 按esc快速重开
	if Input.is_action_just_pressed("restart"):
		if get_tree() and is_inside_tree():
			get_tree().reload_current_scene()
		
	# 检查输入事件是否为鼠标左键被按下
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 获得鼠标点击的位置
			var mouse_position = get_global_mouse_position()
			if cur_zakoA_slots > 0:
				cur_zakoA_slots -= 1
				generate_prefab_instance(ZakoAPrefab,mouse_position)
			else:
				#print("no more ZakoA slot")
				pass
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 获得鼠标点击的位置
			var mouse_position = get_global_mouse_position()
			if cur_zakoB_slots > 0:
				cur_zakoB_slots -= 1
				generate_prefab_instance(ZakoBPrefab,mouse_position)
			else:
				#print("no more ZakoB slot")
				pass
				
	
	if event.is_action_pressed("s3"):
		#var mouse_position = get_global_mouse_position()
		var mouse_position = player.global_position
		if cur_zakoC_slots > 0:
			cur_zakoC_slots -= 1
			generate_prefab_instance(ZakoCPrefab,mouse_position)
		else:
			#print("no more ZakoC slot")
			pass
		
	if event.is_action_pressed("debug_generate_monster"):
		var mouse_position = get_global_mouse_position()
		generate_prefab_instance(MonsterPrefab,mouse_position)
		
		
	
func generate_prefab_instance(prefab:PackedScene,pos:Vector2):
	#if ZakoAPrefab != prefab:# ZakoA太多了，容易卡，跳过
	$GenSFX.playing = true
	var click_vfx = CLICK_PARTICLE.instantiate()
	click_vfx.global_position = pos
	if level_root:
		level_root.add_child(click_vfx)
	else:
		add_child(click_vfx)
	click_vfx.emitting = true
	
	# 实例化一个新的对象
	var new_object = prefab.instantiate()
	# 设置新对象的位置为鼠标点击的位置
	new_object.global_position = pos
	# 将新对象添加为当前节点的子节点
	if level_root:
		level_root.add_child(new_object)
	else:
		add_child(new_object)
		
	# update gui info
	refresh_gui_zako()

func _physics_process(_delta):
	# 胜利检查
	if not has_wined and final_root:
		if final_root.get_child_count() <= 0:
			has_wined = true
			print_debug("You win the game!")
			win_anim_player.play("play")
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	fps_label.text = "FPS " + str(fps)
	pass
	
func _on_player_died():
	died_anim_player.play("play")

func _on_player_picked_item(item_type:Item.ItemType,count):
	$PickupSFX.playing = true
	match item_type:
		Item.ItemType.POTION_GREEN:
			cur_zakoA_slots += count
		Item.ItemType.POTION_BLUE:
			cur_zakoB_slots += count
		Item.ItemType.POTION_PURPLE:
			cur_zakoC_slots += count
		Item.ItemType.KEY_YELLOW:
			cur_key_yellow += 1
		Item.ItemType.KEY_BLUE:
			cur_key_blue += 1
		Item.ItemType.KEY_RED:
			cur_key_red += 1
		_:
			pass
			
	refresh_gui()
	pass

func _on_door_interacted(door,door_type):
	match door_type:
		Door.DoorTypes.NORMAL:
			door.open()
			$DoorOpenSFX.playing = true
			refresh_gui()
		Door.DoorTypes.LOCK_YELLOW:
			if cur_key_yellow > 0:
				cur_key_yellow -= 1
				door.open()
				$DoorOpenSFX.playing = true
				refresh_gui()
			else:
				$DoorDenySFX.playing = true
		Door.DoorTypes.LOCK_BLUE:
			if cur_key_blue > 0:
				cur_key_blue -= 1
				door.open()
				$DoorOpenSFX.playing = true
				refresh_gui()
			else:
				$DoorDenySFX.playing = true
		Door.DoorTypes.LOCK_RED:
			if cur_key_red > 0:
				cur_key_red -= 1
				door.open()
				$DoorOpenSFX.playing = true
				refresh_gui()
			else:
				$DoorDenySFX.playing = true
		_:
			pass
	pass

func refresh_gui():
	refresh_gui_zako()
	refresh_gui_key()
	pass

func refresh_gui_zako():
	label_zako_a.text = "" + "I".repeat(floor(cur_zakoA_slots))+ ( str(cur_zakoA_slots) if cur_zakoA_slots > 0 else "")
	label_zako_b.text = "" + "I".repeat(floor(cur_zakoB_slots))+ ( str(cur_zakoB_slots) if cur_zakoB_slots > 0 else "")
	label_zako_c.text = "" + "I".repeat(floor(cur_zakoC_slots))+ ( str(cur_zakoC_slots) if cur_zakoC_slots > 0 else "")

func refresh_gui_key():
	label_key_yellow.text = str(cur_key_yellow)
	label_key_blue.text = str(cur_key_blue)
	label_key_red.text = str(cur_key_red)
	
