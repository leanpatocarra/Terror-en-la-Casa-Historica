extends Label
func _ready() -> void:
	$Timer.timeout.connect(queue_free)
