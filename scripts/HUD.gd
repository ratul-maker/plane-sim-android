extends CanvasLayer

var plane: Aircraft
var speed_label: Label
var alt_label: Label
var throttle_label: Label
var status_label: Label
var throttle_bar: ProgressBar
var heading_label: Label
var vspeed_label: Label
var warning_label: Label
var touch_layer: Control
var joystick_base: TextureRect
var joystick_knob: TextureRect
var joystick_center: Vector2 = Vector2(180, 560)
var joystick_radius: float = 120.0
var touch_id: int = -1
var touch_start: Vector2 = Vector2.ZERO
var button_size: int = 96
var knob_size: int = 64
var base_size: int = 128

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var panel := PanelContainer.new()
    panel.position = Vector2(20, 20)
    panel.custom_minimum_size = Vector2(280, 240)
    root.add_child(panel)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 4)
    panel.add_child(vbox)

    speed_label = _mk("SPD 0")
    alt_label = _mk("ALT 0")
    heading_label = _mk("HDG 0")
    vspeed_label = _mk("V/S 0")
    throttle_label = _mk("THR 0%")
    status_label = _mk("ON GROUND")
    vbox.add_child(speed_label)
    vbox.add_child(alt_label)
    vbox.add_child(heading_label)
    vbox.add_child(vspeed_label)
    vbox.add_child(throttle_label)
    vbox.add_child(status_label)

    throttle_bar = ProgressBar.new()
    throttle_bar.max_value = 100
    throttle_bar.custom_minimum_size = Vector2(260, 14)
    vbox.add_child(throttle_bar)

    warning_label = Label.new()
    warning_label.text = ""
    warning_label.add_theme_font_size_override("font_size", 42)
    warning_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
    warning_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    warning_label.add_theme_constant_override("outline_size", 6)
    warning_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    warning_label.offset_top = 120
    warning_label.offset_bottom = 200
    warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(warning_label)

    touch_layer = Control.new()
    touch_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    touch_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    touch_layer.gui_input.connect(_on_touch_layer_input)
    root.add_child(touch_layer)

    joystick_base = TextureRect.new()
    joystick_base.texture = _circle(base_size, Color(1, 1, 1, 0.15))
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    touch_layer.add_child(joystick_base)

    joystick_knob = TextureRect.new()
    joystick_knob.texture = _circle(knob_size, Color(1, 1, 1, 0.35))
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    touch_layer.add_child(joystick_knob)

    _make_button("THR+", Vector2(-120, -240), "_on_thr_up")
    _make_button("THR-", Vector2(-120, -120), "_on_thr_down")
    _make_button("BRAKE", Vector2(-240, -120), "_on_brake")
    _make_button("RESET", Vector2(-240, -240), "_on_reset")
    _make_button("CAM", Vector2(-360, -120), "_on_cam")
    _make_button("GEAR", Vector2(-360, -240), "_on_gear")

    call_deferred("_update_joystick_position")

func _update_joystick_position() -> void:
    var vs := get_viewport().get_visible_rect().size
    joystick_center = Vector2(180, vs.y - 160)
    joystick_base.position = joystick_center - Vector2(base_size / 2, base_size / 2)
    joystick_knob.position = joystick_center - Vector2(knob_size / 2, knob_size / 2)

func _mk(t: String) -> Label:
    var l := Label.new()
    l.text = t
    l.add_theme_font_size_override("font_size", 20)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    l.add_theme_constant_override("outline_size", 4)
    return l

func _make_button(t: String, offset: Vector2, method: String) -> void:
    var holder := Control.new()
    holder.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    holder.offset_left = offset.x
    holder.offset_top = offset.y
    holder.offset_right = offset.x + button_size
    holder.offset_bottom = offset.y + button_size
    holder.mouse_filter = Control.MOUSE_FILTER_PASS
    touch_layer.add_child(holder)

    var b := TextureButton.new()
    b.texture_normal = _circle(button_size, Color(1, 1, 1, 0.25))
    b.texture_pressed = _circle(button_size, Color(1, 1, 1, 0.5))
    b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    b.set_anchors_preset(Control.PRESET_FULL_RECT)
    b.offset_left = 0
    b.offset_top = 0
    b.offset_right = 0
    b.offset_bottom = 0
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.pressed.connect(Callable(self, method))
    holder.add_child(b)

    var lbl := _mk(t)
    lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
    lbl.offset_top = button_size / 2 - 14
    lbl.offset_bottom = button_size / 2 + 14
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(lbl)

func _circle(s: int, c: Color) -> ImageTexture:
    var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var ctr := Vector2(s * 0.5, s * 0.5)
    var r: float = s * 0.45
    for y in s:
        for x in s:
            if Vector2(x, y).distance_to(ctr) <= r:
                img.set_pixel(x, y, c)
    return ImageTexture.create_from_image(img)

func _on_thr_up() -> void:
    if plane:
        plane.set_throttle(plane.throttle + 0.15)

func _on_thr_down() -> void:
    if plane:
        plane.set_throttle(plane.throttle - 0.15)

func _on_brake() -> void:
    if plane:
        plane.brake_input = true

func _on_reset() -> void:
    if plane:
        plane.reset()

func _on_cam() -> void:
    var main := get_parent()
    if main and "camera_mode" in main:
        main.camera_mode = (main.camera_mode + 1) % 3

func _on_gear() -> void:
    if plane:
        plane.toggle_gear()

func _on_touch_layer_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t: InputEventScreenTouch = event
        if t.pressed and touch_id == -1 and t.position.distance_to(joystick_center) < 200.0 and t.position.x < 700.0:
            touch_id = t.index
            touch_start = t.position
        elif not t.pressed and t.index == touch_id:
            touch_id = -1
            if plane:
                plane.pitch_input = 0.0
                plane.roll_input = 0.0
            joystick_knob.position = joystick_center - Vector2(knob_size / 2, knob_size / 2)
    elif event is InputEventScreenDrag:
        var d: InputEventScreenDrag = event
        if d.index == touch_id and plane:
            var delta: Vector2 = d.position - touch_start
            var dir: Vector2 = delta.limit_length(joystick_radius)
            plane.pitch_input = clamp(-dir.y / joystick_radius, -1.0, 1.0)
            plane.roll_input = clamp(dir.x / joystick_radius, -1.0, 1.0)
            joystick_knob.position = joystick_center + dir - Vector2(knob_size / 2, knob_size / 2)

func _process(_delta: float) -> void:
    if not plane:
        return
    speed_label.text = "SPD %d km/h" % int(plane.get_speed_kmh())
    alt_label.text = "ALT %d m" % int(plane.get_altitude())
    heading_label.text = "HDG %d" % int(plane.get_heading())
    vspeed_label.text = "V/S %d m/s" % int(plane.get_vertical_speed())
    throttle_label.text = "THR %d%%" % int(plane.throttle * 100.0)
    throttle_bar.value = int(plane.throttle * 100.0)
    status_label.text = "ON GROUND" if plane.on_ground else "AIRBORNE"
    if plane.crashed:
        warning_label.text = "CRASHED"
    elif plane.stall_warning:
        warning_label.text = "STALL"
    else:
        warning_label.text = ""
