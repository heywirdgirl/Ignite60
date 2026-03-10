extends Control

const LOOP_DURATION : int = 60
const DEFAULT_LOOPS : int = 10

const C_BG         = Color(0.051, 0.051, 0.051)
const C_SURFACE    = Color(0.102, 0.102, 0.102)
const C_BORDER     = Color(0.165, 0.165, 0.165)
const C_ACCENT     = Color(1.0,   0.2,   0.2  )
const C_ACCENT_DIM = Color(0.4,   0.067, 0.067)
const C_TEXT       = Color(0.91,  0.91,  0.91 )
const C_TEXT_DIM   = Color(0.4,   0.4,   0.4  )
const C_SUCCESS    = Color(0.267, 1.0,   0.533)

var FONT_HUGE  : int = 88
var FONT_LARGE : int = 26
var FONT_MED   : int = 18
var FONT_SMALL : int = 14

var lbl_timer   : Label
var lbl_loop    : Label
var lbl_message : Label
var progress    : ProgressBar
var btn_start   : Button
var btn_reset   : Button
var spin_loops  : SpinBox
var tick_timer  : Timer
var quit_timer  : Timer
var beep_player : AudioStreamPlayer

var total_loops  : int  = DEFAULT_LOOPS
var current_loop : int  = 1
var seconds_left : int  = LOOP_DURATION
var is_running   : bool = false
var is_paused    : bool = false

func _ready() -> void:
	_calc_font_sizes()
	_build_ui()
	_connect_signals()
	_reset_state()

func _calc_font_sizes() -> void:
	var h : float = get_viewport().get_visible_rect().size.y
	var scale : float = clamp(h / 854.0, 0.6, 1.6)
	FONT_HUGE  = int(88 * scale)
	FONT_LARGE = int(26 * scale)
	FONT_MED   = int(18 * scale)
	FONT_SMALL = int(14 * scale)

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	var bg := ColorRect.new()
	bg.color         = C_BG
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.alignment             = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(vbox)

	_spacer(vbox, 48)

	var lbl_title := _make_label("🔥 IGNITE60", FONT_LARGE, C_TEXT)
	lbl_title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_margin(vbox, lbl_title, 24, 0, 24, 8)

	vbox.add_child(_make_hsep())
	_spacer(vbox, 24)

	lbl_timer = _make_label("01:00", FONT_HUGE, C_ACCENT)
	lbl_timer.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_timer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_add_margin(vbox, lbl_timer, 24, 0, 24, 0)

	_spacer(vbox, 16)

	lbl_loop = _make_label("Loop 1 / 10", FONT_MED, C_TEXT_DIM)
	lbl_loop.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl_loop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_margin(vbox, lbl_loop, 24, 0, 24, 0)

	_spacer(vbox, 24)

	progress = _make_progressbar()
	_add_margin(vbox, progress, 32, 0, 32, 0)

	_spacer(vbox, 24)

	lbl_message = _make_label("", FONT_MED, C_SUCCESS)
	lbl_message.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_message.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl_message.visible               = false
	_add_margin(vbox, lbl_message, 32, 0, 32, 0)

	_spacer(vbox, 16)
	vbox.add_child(_make_hsep())
	_spacer(vbox, 24)

	var loops_row := HBoxContainer.new()
	loops_row.alignment             = BoxContainer.ALIGNMENT_CENTER
	loops_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loops_row.add_theme_constant_override("separation", 12)
	loops_row.add_child(_make_label("Loops:", FONT_SMALL, C_TEXT_DIM))

	spin_loops = SpinBox.new()
	spin_loops.min_value           = 1
	spin_loops.max_value           = 20
	spin_loops.value               = DEFAULT_LOOPS
	spin_loops.custom_minimum_size = Vector2(100, 44)
	spin_loops.add_theme_font_size_override("font_size", FONT_MED)
	loops_row.add_child(spin_loops)
	_add_margin(vbox, loops_row, 24, 0, 24, 0)

	_spacer(vbox, 20)

	var btn_col := VBoxContainer.new()
	btn_col.alignment             = BoxContainer.ALIGNMENT_CENTER
	btn_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_col.add_theme_constant_override("separation", 12)

	btn_start = _make_btn("▶  Start", C_ACCENT,  C_BG,       0, 56)
	btn_reset = _make_btn("↺  Reset", C_SURFACE, C_TEXT_DIM, 0, 48)
	btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_col.add_child(btn_start)
	btn_col.add_child(btn_reset)
	_add_margin(vbox, btn_col, 32, 0, 32, 0)

	_spacer(vbox, 48)

	tick_timer           = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.one_shot  = false
	tick_timer.autostart = false
	add_child(tick_timer)

	quit_timer           = Timer.new()
	quit_timer.wait_time = 5.0
	quit_timer.one_shot  = true
	quit_timer.autostart = false
	add_child(quit_timer)

	beep_player           = AudioStreamPlayer.new()
	beep_player.stream    = _gen_beep()
	beep_player.volume_db = -6.0
	add_child(beep_player)

func _on_viewport_resized() -> void:
	size = get_viewport_rect().size

func _connect_signals() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	tick_timer.timeout.connect(_on_tick)
	quit_timer.timeout.connect(_on_quit)

func _on_quit() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	if not is_running:
		total_loops         = int(spin_loops.value)
		current_loop        = 1
		seconds_left        = LOOP_DURATION
		is_running          = true
		is_paused           = false
		lbl_message.visible = false
		spin_loops.editable = false
		progress.max_value  = LOOP_DURATION
		progress.value      = LOOP_DURATION
		lbl_loop.text       = "Loop 1 / %d" % total_loops
		_set_start_btn("⏸  Pause", C_ACCENT_DIM)
		_update_display()
		tick_timer.start()
	elif is_paused:
		is_paused = false
		_set_start_btn("⏸  Pause", C_ACCENT_DIM)
		tick_timer.start()
	else:
		is_paused = true
		_set_start_btn("▶  Resume", C_ACCENT)
		tick_timer.stop()

func _on_reset_pressed() -> void:
	tick_timer.stop()
	quit_timer.stop()
	is_running          = false
	is_paused           = false
	spin_loops.editable = true
	_reset_state()

func _on_tick() -> void:
	seconds_left -= 1
	_update_display()
	if seconds_left <= 0:
		beep_player.play()
		current_loop += 1
		if current_loop > total_loops:
			_finish()
		else:
			seconds_left  = LOOP_DURATION
			lbl_loop.text = "Loop %d / %d" % [current_loop, total_loops]

func _finish() -> void:
	tick_timer.stop()
	is_running  = false
	lbl_timer.add_theme_color_override("font_color", C_SUCCESS)
	lbl_timer.text      = "Done!"
	lbl_loop.text       = "All %d loops complete ✓" % total_loops
	lbl_message.text    = "🎯 Warm-up complete.\nStart focusing now."
	lbl_message.visible = true
	spin_loops.editable = true
	_set_start_btn("▶  Start", C_ACCENT)
	quit_timer.start()

func _reset_state() -> void:
	current_loop = 1
	seconds_left = LOOP_DURATION
	total_loops  = int(spin_loops.value) if spin_loops else DEFAULT_LOOPS
	if lbl_timer:
		lbl_timer.text = _fmt(LOOP_DURATION)
		lbl_timer.add_theme_color_override("font_color", C_ACCENT)
	if lbl_loop:
		lbl_loop.text = "Loop 1 / %d" % total_loops
	if progress:
		progress.max_value = LOOP_DURATION
		progress.value     = LOOP_DURATION
	if lbl_message:
		lbl_message.visible = false
	if btn_start:
		_set_start_btn("▶  Start", C_ACCENT)

func _update_display() -> void:
	lbl_timer.text = _fmt(seconds_left)
	progress.value = seconds_left

func _fmt(s: int) -> String:
	if s >= 60:
		return "%02d:%02d" % [s / 60, s % 60]
	return str(s)

func _set_start_btn(txt: String, color: Color) -> void:
	btn_start.text = txt
	btn_start.add_theme_stylebox_override("normal",  _flat(color, 10))
	btn_start.add_theme_stylebox_override("hover",   _flat(color.lightened(0.15), 10))
	btn_start.add_theme_stylebox_override("pressed", _flat(color.darkened(0.2), 10))

func _make_label(p_text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = p_text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _make_btn(p_text: String, bg: Color, fg: Color, w: int, h: int) -> Button:
	var b := Button.new()
	b.text                = p_text
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_font_size_override("font_size", FONT_MED)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_stylebox_override("normal",  _flat(bg, 10))
	b.add_theme_stylebox_override("hover",   _flat(bg.lightened(0.15), 10))
	b.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.2), 10))
	return b

func _make_progressbar() -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value             = 0
	pb.max_value             = LOOP_DURATION
	pb.value                 = LOOP_DURATION
	pb.show_percentage       = false
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size   = Vector2(0, 16)
	pb.add_theme_stylebox_override("background", _flat(C_BORDER, 8))
	pb.add_theme_stylebox_override("fill",       _flat(C_ACCENT, 8))
	return pb

func _make_hsep() -> HSeparator:
	var sep := HSeparator.new()
	var st  := StyleBoxFlat.new()
	st.bg_color = C_BORDER
	sep.add_theme_stylebox_override("separator", st)
	sep.add_theme_constant_override("separation", 1)
	return sep

func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color                   = color
	st.corner_radius_top_left     = radius
	st.corner_radius_top_right    = radius
	st.corner_radius_bottom_left  = radius
	st.corner_radius_bottom_right = radius
	return st

func _add_margin(parent: Control, child: Control, ml: int, mt: int, mr: int, mb: int) -> void:
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_theme_constant_override("margin_left",   ml)
	mc.add_theme_constant_override("margin_top",    mt)
	mc.add_theme_constant_override("margin_right",  mr)
	mc.add_theme_constant_override("margin_bottom", mb)
	mc.add_child(child)
	parent.add_child(mc)

func _spacer(parent: Control, height: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	parent.add_child(s)

func _gen_beep() -> AudioStreamWAV:
	var stream       := AudioStreamWAV.new()
	stream.format    = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate  = 22050
	stream.stereo    = false
	var duration     : float = 0.25
	var freq         : float = 880.0
	var n            : int   = int(22050.0 * duration)
	var data         := PackedByteArray()
	data.resize(n)
	for i in n:
		var t   : float = float(i) / 22050.0
		var env : float = 1.0 - (t / duration)
		var val : float = sin(TAU * freq * t) * env
		data[i] = int(clamp(val * 120.0 + 128.0, 0.0, 255.0))
	stream.data = data
	return stream
