extends Node

onready var item_list = $GUI/Panel/GridContainer/Panel4/HBoxContainer/ItemList
onready var item_list1_container = $GUI/Panel/GridContainer/Panel6/HBoxContainer
onready var text_edit = $GUI/Panel/GridContainer/Panel5/VBoxContainer/TextEdit
onready var change_panel = $GUI/Panel/GridContainer/Panel5/VBoxContainer/ChangePanel

var load_template_thread = Thread.new()
var save_keywords_thread = Thread.new()

func _ready():
	text_edit.add_color_region("[", "]", Color.orange)
	text_edit.add_color_region(";", "", Color.dimgray)
	
func _enter_tree():
	load_template_thread.start(self, "load_template")
	
func _exit_tree():
	if load_template_thread.is_active():
		load_template_thread.wait_to_finish()

func load_template(userdata):
	var file = File.new()
	if file.open("res://template/reaper650.ReaperLangPack", File.READ) != OK:
		return
	var text = file.get_as_text()
	file.close()
	
	var part_name = ""
	var part_from = 0
	var part_end = 0
	var num_parts = 0
	var is_part =  false
	
	for num in text.length():
		#
		if !is_part && text[num] == "[":
			part_from = num
			var _num = num
			
			while true:
				part_name += text[_num]
				if text[_num] == "]":
					break
				_num += 1
			is_part = true
		#
		if is_part && text[num] == "\n" && text[num + 1] == "[":
			part_end = num
					
			var _text = text.substr(part_from, part_end - part_from)
#			var _file = File.new()
#			_file.open("res://out/" + part_name + ".txt", File.WRITE)
#			_file.store_string(_text)
#			_file.close()
			
			item_list.add_item(part_name)
			item_list.set_item_metadata(num_parts, { "text" : _text })
			
			num_parts += 1
			part_name = ""
			is_part = false
		#
		if is_part && num == text.length() - 1:
			part_end = num
					
			var _text = text.substr(part_from, part_end - part_from + 1)
#			var _file = File.new()
#			_file.open("res://out/" + part_name + ".txt", File.WRITE)
#			_file.store_string(_text)
#			_file.close()
			
			item_list.add_item(part_name)
			item_list.set_item_metadata(num_parts, { "text" : _text + "\n" })
			
			num_parts += 1
			part_name = ""
			is_part = false

func _on_ItemList_item_selected(index):
	text_edit.text = item_list.get_item_metadata(index)["text"]
	item_list1_container.get_child(0).clear()
	
	var part_name =  item_list.get_item_text(item_list.get_selected_items()[0])
	var dir = Directory.new()
	if dir.file_exists("res://temp/" + part_name + ".tscn"):
		var _item_list1_file = load("res://temp/" + part_name + ".tscn")
		var _item_list1 = _item_list1_file.instance()
		
		item_list1_container.remove_child(item_list1_container.get_child(0))
		item_list1_container.add_child(_item_list1)
	else:
		save_keywords_thread.start(self, "save_keywords")

func save_keywords(userdata):
	item_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var key_word = ""
	var is_key_word = false
	var key_words = 0
	var meta_data = item_list.get_item_metadata(item_list.get_selected_items()[0])
	var part_name =  item_list.get_item_text(item_list.get_selected_items()[0])
	
	for num in text_edit.text.length():
		pass
		#
		if !is_key_word && text_edit.text[num] == "=":
			var _num = num + 1
			while true:
				key_word += text_edit.text[_num]
				_num += 1
				if text_edit.text[_num - 1] == "\n":
					break
				if text_edit.text[_num] == "\n":
					break
			is_key_word = true
		#
		if is_key_word && text_edit.text[num] == "\n":
			meta_data[key_word] = ""
			
			item_list1_container.get_child(0).add_item(key_word)
			
			key_words += 1
			key_word = ""
			is_key_word = false
	
	item_list.set_item_metadata(item_list.get_selected_items()[0], meta_data)
	
	var meta_data_res = Metadata.new()
	meta_data_res.data = meta_data
	ResourceSaver.save("res://temp/" + part_name + ".tres", meta_data_res)
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(item_list1_container.get_child(0))
	ResourceSaver.save("res://temp/" + part_name + ".tscn", packed_scene)
	
	item_list.mouse_filter = Control.MOUSE_FILTER_STOP
	
	save_keywords_thread.call_deferred("wait_to_finish")

func _on_GUI_resized():
	$GUI/Panel/GridContainer/Panel4.rect_min_size.x = ($GUI.rect_size / Vector2(1280, 720) * 150).x
	$GUI/Panel/GridContainer/Panel6.rect_min_size.x = $GUI/Panel/GridContainer/Panel4.rect_min_size.x
	$GUI/Panel/GridContainer/Panel4/HBoxContainer/ItemList.fixed_column_width = ($GUI.rect_size / Vector2(1280, 720) * 130).x
	$GUI/Panel/GridContainer/Panel6/HBoxContainer/ItemList.fixed_column_width = $GUI/Panel/GridContainer/Panel4/HBoxContainer/ItemList.fixed_column_width

func _on_Button_button_down():
	text_edit.visible = false if text_edit.visible == true else true

func _on_Button2_button_down():
	change_panel.visible = false if change_panel.visible == true else true
