extends StaticBody2D
class_name Item

enum ItemType
{
	POTION_GREEN,
	POTION_BLUE,
	POTION_PURPLE,
	KEY_YELLOW,
	KEY_BLUE,
	KEY_RED,
}
@export var item_type = ItemType.POTION_GREEN
@export var count = 1
