extends Control
@onready var buttonLeft = $buttonLeft/left
@onready var buttonRight = $buttonRight/right
@onready var buttonLeftIniPos = $buttonLeft/left.position
@onready var buttonRightIniPos = $buttonRight/right.position
@onready var buttonGlobIniPos = [$buttonLeft/left.global_position,$buttonRight/right.global_position]
@onready var label = $panel/label
@onready var panel = $panel
@export var extendsMoveUI = 60000
var flipped = false
var cards = [["Default Text","Default Answer"],["Default Text 2","Default Answer 2"]]
var colours = [[Color8(29, 30, 24),Color8(185, 245, 216),Color8(235, 245, 238),Color8(29, 30, 24),Color8(170, 210, 186)],[Color8(206, 120, 107),Color8(46, 31, 39),Color8(46, 31, 39),Color8(206, 120, 107),Color8(236, 200, 175)]]
var cardIndex = 0
var floatTime = 0.0
var move = [false,false]
var divisorValue = 2
var pressed = false
var in_bounds = false
var backgroundColorValue = 0
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$cardset.add_item("Default")
	cards.shuffle()
	cardIndex = rng.randi_range(0, len(cards)-1)
	set_card(cards[cardIndex][int(flipped)],0)
	$background.self_modulate = colours[backgroundColorValue][4]
	var dir = DirAccess.open("user://card sets")
	print(dir)
	if dir == null:
		var dirMake = DirAccess.open("user://")
		dirMake.make_dir("card sets")
		dir = DirAccess.open("user://card sets")
	if len(dir.get_files()) == 0:
		var indexText = FileAccess.open("user://card sets/Example", FileAccess.WRITE)
		indexText.store_string("Default Text||Default Answer\nDefault Text 2||Default Answer 2")
	for files in dir.get_files():
		$cardset.add_item(files)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	floatTime += delta
	check_position(buttonLeft,buttonLeftIniPos,1,2,0,20)
	check_position(buttonRight,buttonRightIniPos,2,1,1,20)
	if backgroundColorValue == 2:
		$background.self_modulate = Color((sin(floatTime/10)+1),((sin((floatTime*1.2))+1)/divisorValue),((sin((floatTime*1.3)/10)+1)/divisorValue)) 
	var direction_axis_button = get_axis(buttonLeft.button_pressed,buttonRight.button_pressed)
	var swap_card_input = Input.get_axis("ui_left","ui_right")
	var swap_background_input =  Input.get_axis("ui_down","ui_up")
	if Input.is_action_just_pressed("shuffle"):
		$sort.run([colours[backgroundColorValue][0],colours[backgroundColorValue][2]])
		cards.shuffle()
		cardIndex = 0
		set_card(cards[cardIndex][int(flipped)],0)
		pressed = true
	elif swap_card_input != 0:
		if not pressed:
			pressed = true
			swap_card_thing_apply(swap_card_input)
	elif direction_axis_button != 0:
		if not pressed:
			pressed = true
			swap_card_thing_apply(direction_axis_button)
	elif swap_background_input != 0:
		if not pressed:
			pressed = true
			backgroundColorValue += swap_background_input
			if backgroundColorValue < 0:
				backgroundColorValue = (len(colours))-1
			elif backgroundColorValue > (len(colours))-1:
				backgroundColorValue = 0
			flipped = false
			if backgroundColorValue != 2:
				$background.self_modulate = colours[backgroundColorValue][4]
				$panel.self_modulate =  colours[backgroundColorValue][int(flipped)]
				label.set("theme_override_colors/font_color", colours[backgroundColorValue][int(flipped)+2])
	elif Input.is_anything_pressed() and direction_axis_button == 0 and not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		if not pressed:
			pressed = true
			flipped = not flipped
			swap(cards[cardIndex][int(flipped)],flipped)
	elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) and in_bounds:
		if not pressed:
			pressed = true
			flipped = not flipped
			swap(cards[cardIndex][int(flipped)],flipped)
	else:
		pressed = false

func get_axis(left:bool,right:bool):
	return int(right)-int(left)

func set_card(text,direction):
	var movePos = $originPos.position
	var tween = get_tree().create_tween()
	tween.bind_node(panel)
	if direction != 0:
		if direction == -1:
			tween.tween_property(panel,"position",Vector2(-movePos.x,movePos.y),0.5).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(panel,"position",Vector2(movePos.x*3,movePos.y),0.0).set_ease(Tween.EASE_IN_OUT)
		else:
			tween.tween_property(panel,"position",Vector2(movePos.x*3,movePos.y),0.5).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(panel,"position",Vector2(-movePos.x,movePos.y),0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label,"text",text,0)
	tween.tween_callback(go_flip_off)
	tween.tween_property(panel,"self_modulate",colours[backgroundColorValue][int(flipped)],0)
	tween.chain().tween_property(panel,"position",movePos,0.5)

func swap(text: String,flipped: bool):
	var movePos = $originPos.position
	var tween = get_tree().create_tween().set_parallel(true)
	tween.bind_node(panel)
	tween.chain().tween_property(panel,"scale",Vector2(1,0),0.5)
	tween.tween_property(panel,"position",Vector2(movePos.x,movePos.y+(panel.size/2).y),0.5)
	tween.chain().tween_property(panel,"scale",Vector2(1,1),0.5)
	tween.tween_property(panel,"position",movePos,0.5)
	tween.tween_property(label,"text",text,0)
	tween.tween_callback(go_flip_off)
	tween.tween_property(panel,"self_modulate",colours[backgroundColorValue][int(flipped)],0)


func go_flip_off():
	label.set("theme_override_colors/font_color", colours[backgroundColorValue][int(flipped)+2])

func check_position(button,buttonIniPos:Vector2,m1:float,m2:float,m:int,p:float):
	if get_global_mouse_position().distance_squared_to(button.global_position) < extendsMoveUI:
		move[m] = true
		var mouseAngle = buttonGlobIniPos[m].angle_to_point(get_global_mouse_position())
		button.position = buttonIniPos+(Vector2(cos(mouseAngle)*20, sin(mouseAngle)*20))
	elif move[m] == true:
		var tween = get_tree().create_tween()
		tween.tween_property(button, "position", buttonIniPos+Vector2(cos((floatTime+0.2)*m1),sin((floatTime+0.2)*m2))*p, 0.2)
		if m == 1:
			move = [move[0],false]
		else:
			move = [false,move[1]]
	else:
		button.position = buttonIniPos+Vector2(cos((floatTime)*m1),sin((floatTime)*m2))*p


func _on_cardset_item_selected(index):
	if index == 0:
		cards = [["Default Text","Default Answer"],["Default Text 2","Default Answer 2"]]
	else:
		cards = []
		var indexText = FileAccess.open("user://card sets/"+$cardset.get_item_text(index), FileAccess.READ).get_as_text()
		for string in indexText.split("\n"):
			cards.append(string.split("||"))
	set_card(cards[cardIndex][int(flipped)],0)



func _on_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://card sets"))


func _on_panel_mouse_entered():
	in_bounds = true


func _on_panel_mouse_exited():
	in_bounds = false


func _on_refresh_pressed():
	var dir = DirAccess.open("user://card sets")
	$cardset.clear()
	$cardset.add_item("Default")
	for files in dir.get_files():
		$cardset.add_item(files)
	_on_cardset_item_selected(0)


func _on_shuffle_pressed():
	flipped = false
	cards.shuffle()
	cardIndex = 0
	set_card(cards[cardIndex][int(flipped)],0)

func swap_card_thing_apply(swap_card_input):
	if not ((cardIndex+swap_card_input < 0) or (cardIndex+swap_card_input > len(cards)-1)):
		flipped = false
		cardIndex += swap_card_input
		set_card(cards[cardIndex][int(flipped)],swap_card_input)
