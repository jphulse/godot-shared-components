extends Node

@onready var test_player: Node2D = $TestPlayer


func _ready() -> void:
	print("--- SAVE TEST START ---")

	test_player.position = Vector2(100, 200)
	test_player.health = 75
	test_player.gold = 12

	print("Before save:")
	_print_player_state()

	SaveManager.save_game("test_slot")
	print("Saved file to location on computer \t",ProjectSettings.globalize_path("user://saves/test_slot/player.tres"), "\n")
	test_player.position = Vector2(999, 999)
	test_player.health = 1
	test_player.gold = 0

	print("After mutation:")
	_print_player_state()

	SaveManager.load_game("test_slot")

	print("After load:")
	_print_player_state()

	assert(test_player.position == Vector2(100, 200))
	assert(test_player.health == 75)
	assert(test_player.gold == 12)

	print("--- SAVE TEST PASSED ---")
	
	SaveManager.delete_save("test_slot")
	assert(not SaveManager.save_exists("test_slot"))

	print("--- DELETE TEST PASSED ---")


func _print_player_state() -> void:
	print("Position: ", test_player.position)
	print("Health: ", test_player.health)
	print("Gold: ", test_player.gold)
