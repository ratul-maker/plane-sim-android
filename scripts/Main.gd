extends Node3D

@onready var plane: Aircraft = $Plane
@onready var camera: Camera3D = $Camera3D
@onready var hud = $HUD

var camera_mode: int = 0
var camera_offset_chase: Vector3 = Vector3(0, 4, 14)
var camera_offset_cockpit: Vector3 = Vector3(0, 1.1, -0.5)
var cinematic_angle: float = 0.0

func _ready() -> void:
    _style_world()
    hud.plane = plane
    plane.crashed_signal.connect(_on_crash)

func _style_world() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    var mi := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(4000, 4000)
    mi.mesh = pm
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.28, 0.42, 0.22)
    mat.roughness = 1.0
    mi.material_override = mat
    ground.add_child(mi)
    var cs := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(4000, 1, 4000)
    cs.shape = shape
    cs.position = Vector3(0, -0.5, 0)
    ground.add_child(cs)
    add_child(ground)

    var runway := MeshInstance3D.new()
    var rmesh := BoxMesh.new()
    rmesh.size = Vector3(20, 0.1, 400)
    runway.mesh = rmesh
    runway.position = Vector3(0, 0.02, -200)
    var rmat := StandardMaterial3D.new()
    rmat.albedo_color = Color(0.15, 0.15, 0.17)
    rmat.roughness = 0.9
    runway.material_override = rmat
    add_child(runway)

    for i in range(-9, 10):
        var stripe := MeshInstance3D.new()
        var sm := BoxMesh.new()
        sm.size = Vector3(0.8, 0.11, 6)
        stripe.mesh = sm
        stripe.position = Vector3(0, 0.03, -200 + i * 20.0)
        var smat := StandardMaterial3D.new()
        smat.albedo_color = Color(0.95, 0.95, 0.95)
        stripe.material_override = smat
        add_child(stripe)

    for i in range(-4, 5):
        if i == 0:
            continue
        var tb := MeshInstance3D.new()
        var tm := BoxMesh.new()
        tm.size = Vector3(1.2, 0.11, 5)
        tb.mesh = tm
        tb.position = Vector3(i * 2.0, 0.03, -395)
        var tmat := StandardMaterial3D.new()
        tmat.albedo_color = Color(0.95, 0.95, 0.95)
        tb.material_override = tmat
        add_child(tb)

func _process(delta: float) -> void:
    _update_camera(delta)
    if Input.is_action_just_pressed("camera_toggle"):
        camera_mode = (camera_mode + 1) % 3
    if Input.is_action_just_pressed("reset_plane"):
        plane.reset()
    if Input.is_action_just_pressed("gear_toggle"):
        plane.toggle_gear()
    if Input.is_action_just_pressed("flaps_up"):
        plane.set_flaps(plane.flaps - 0.25)
    if Input.is_action_just_pressed("flaps_down"):
        plane.set_flaps(plane.flaps + 0.25)
    if Input.is_action_pressed("trim_up"):
        plane.set_trim(plane.trim + delta * 0.2)
    if Input.is_action_pressed("trim_down"):
        plane.set_trim(plane.trim - delta * 0.2)

func _physics_process(delta: float) -> void:
    var ta: float = Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down")
    if ta != 0.0:
        plane.set_throttle(plane.throttle + ta * delta * 0.6)
    plane.pitch_input = Input.get_action_strength("pitch_down") - Input.get_action_strength("pitch_up")
    plane.roll_input = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
    plane.brake_input = Input.is_action_pressed("brake")

func _update_camera(delta: float) -> void:
    var target: Transform3D = plane.global_transform
    var dp: Vector3
    var dl: Vector3
    if camera_mode == 0:
        dp = target.origin + target.basis * camera_offset_chase
        dl = target.origin
    elif camera_mode == 1:
        dp = target.origin + target.basis * camera_offset_cockpit
        dl = target.origin + target.basis * Vector3(0, 1.0, -10)
    else:
        cinematic_angle += delta * 0.3
        var c := Vector3(cos(cinematic_angle) * 25.0, 10.0, sin(cinematic_angle) * 25.0)
        dp = target.origin + c
        dl = target.origin
    camera.global_position = camera.global_position.lerp(dp, clamp(delta * 8.0, 0.0, 1.0))
    camera.look_at(dl, target.basis.y)

func _on_crash() -> void:
    await get_tree().create_timer(2.0).timeout
    if is_instance_valid(plane):
        plane.reset()
