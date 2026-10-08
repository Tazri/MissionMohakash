extends VideoStreamPlayer

const LOOP_START := 4.0
const LOOP_END := 10.0

func _ready():
	stream_position = LOOP_START
	play()

func _process(_delta):
	if stream_position >= LOOP_END:
		stream_position = LOOP_START
