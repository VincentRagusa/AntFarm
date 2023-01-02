extends Button
onready var show_option = get_parent().get_node("right_menu/Tween")

var menu_visable = true
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	if menu_visable== true:
		# hide menu
		show_option.interpolate_property(get_parent().get_node("right_menu"),"rect_position:x",584,1000,.3,Tween.TRANS_LINEAR,Tween.EASE_OUT_IN,0)
		show_option.start()
		menu_visable = false
	else:
		# show menu
		show_option.interpolate_property(get_parent().get_node("right_menu"),"rect_position:x",1000,584,.3,Tween.TRANS_LINEAR,Tween.EASE_IN,0)
		show_option.start()
		get_parent().get_node("right_menu").visible = true
		menu_visable = true

