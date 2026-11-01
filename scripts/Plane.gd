extends RigidBody3D
class_name Aircraft

@export var max_thrust: float = 9000.0
@export var lift_coefficient: float = 9.0
@export var drag_coefficient: float = 0.06
@export var lateral_drag: float = 2.5
@export var pitch_torque: float = 9000.0
@export var roll_torque: float = 14000.0
@export var yaw_torque: float = 6000.0
@export var brake_strength: float = 0.985
@export var min_takeoff_speed: float = 22.0
@export var stall_speed: float = 18.0
@export var crash_impact_speed: float = 18.0

var throttle: float = 0.0
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0
var brake_input: bool = false
var on_ground: bool = true
var forward_speed: float = 0.0
var spawn_transform: Transform3D
var gear_down: bool = true
var flaps: float = 0.0
var trim: float = 0.0
var crashed: bool = false
var stall_warning: bool = false

signal crashed_signal

func _ready() -> void:
    spawn_transform = global_transform
    contact_monitor = true
    max_contacts_reported = 4
    body_entered.connect(_on_body_entered)

func reset() -> void:
    global_transform = spawn_transform
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    throttle = 0.0
    crashed = false
    gear_down = true
    flaps = 0.0
    trim = 0.0
    stall_warning = false
    forward_speed = 0.0

func _physics_process(_delta: float) -> void:
    if crashed:
        return
    _check_ground()
    var bf: Vector3 = -global_transform.basis.z
    var bu: Vector3 = global_transform.basis.y
    var br: Vector3 = global_transform.basis.x
    forward_speed = linear_velocity.dot(bf)

    var flap_lift_bonus: float = 1.0 + flaps * 0.4
    var flap_drag_bonus: float = 1.0 + flaps * 0.6
    var gear_drag: float = 1.15 if gear_down else 1.0

    apply_central_force(bf * max_thrust * throttle)

    if forward_speed > 1.0:
        apply_central_force(bu * lift_coefficient * forward_speed * forward_speed * 0.5 * flap_lift_bonus)

    var fwd_vel: Vector3 = bf * linear_velocity.dot(bf)
    var lat_vel: Vector3 = linear_velocity - fwd_vel
    apply_central_force(-fwd_vel * drag_coefficient * linear_velocity.length() * flap_drag_bonus * gear_drag)
    apply_central_force(-lat_vel * lateral_drag)

    stall_warning = forward_speed < stall_speed and not on_ground
    var authority: float = clamp(forward_speed / max(min_takeoff_speed, 1.0), 0.0, 1.0)
    if not on_ground:
        apply_torque(br * (pitch_input + trim) * pitch_torque * authority)
        apply_torque(bf * roll_input * roll_torque * authority)
        apply_torque(bu * yaw_input * yaw_torque * authority)
    if brake_input and on_ground:
        linear_velocity *= brake_strength
        angular_velocity *= 0.9

    _check_crash()

func _check_ground() -> void:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var q := PhysicsRayQueryParameters3D.create(global_position, global_position - global_transform.basis.y * 2.2)
    q.exclude = [get_rid()]
    on_ground = not space.intersect_ray(q).is_empty()

func _check_crash() -> void:
    if global_position.y < -2.0:
        _do_crash()

func _on_body_entered(_body: Node) -> void:
    var impact: float = linear_velocity.length()
    if impact > crash_impact_speed and not on_ground:
        _do_crash()

func _do_crash() -> void:
    if crashed:
        return
    crashed = true
    crashed_signal.emit()

func toggle_gear() -> void:
    if on_ground and linear_velocity.length() < 3.0:
        gear_down = not gear_down

func set_flaps(v: float) -> void:
    flaps = clamp(v, 0.0, 1.0)

func set_trim(v: float) -> void:
    trim = clamp(v, -0.3, 0.3)

func set_throttle(v: float) -> void:
    throttle = clamp(v, 0.0, 1.0)

func get_speed_kmh() -> float:
    return linear_velocity.length() * 3.6

func get_altitude() -> float:
    return max(0.0, global_position.y)

func get_heading() -> float:
    var fwd := -global_transform.basis.z
    return fposmod(rad_to_deg(atan2(fwd.x, -fwd.z)), 360.0)

func get_vertical_speed() -> float:
    return linear_velocity.y
