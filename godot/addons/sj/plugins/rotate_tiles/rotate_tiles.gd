@tool
extends EditorPlugin


var plugin : EditorInspectorPlugin = preload("inspector_plugin.gd").new()

func _enter_tree():
	add_inspector_plugin(plugin)
	plugin.setup()
	
	print("Rotate Tiles Plugin started")
	

func _exit_tree():
	remove_inspector_plugin(plugin)
	plugin.clean_up()
