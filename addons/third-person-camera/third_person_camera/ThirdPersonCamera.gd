@icon("./ThirdPersonCameraIcon.svg")
@tool
class_name ThirdPersonCamera extends Node3D


@onready var _camera := $Camera
@onready var _camera_rotation_pivot = $RotationPivot
@onready var _camera_offset_pivot = $RotationPivot/OffsetPivot
@onready var _camera_spring_arm := $RotationPivot/OffsetPivot/CameraSpringArm
@onready var _camera_marker := $RotationPivot/OffsetPivot/CameraSpringArm/CameraMarker



## 
@export var distance_from_pivot := 10.0 :
	set(value) :
		distance_from_pivot = value
		$RotationPivot/OffsetPivot/CameraSpringArm.spring_length = distance_from_pivot

## 
@export var pivot_offset := Vector2.ZERO 

##  
@export_range(-90.0, 90.0) var initial_dive_angle_deg := -20.0 :
	set(value) :
		initial_dive_angle_deg = clampf(value, tilt_lower_limit_deg, tilt_upper_limit_deg)

## 
@export_range(-90.0, 90.0) var tilt_upper_limit_deg := 60.0

##
@export_range(-90.0, 90.0) var tilt_lower_limit_deg := -60.0

##
@export_range(1.0, 100.0) var tilt_sensitiveness := 10.0

## 
@export_range(10.0, 700.0) var horizontal_rotation_sensitiveness := 100.0

## 
@export var current : bool = false :
	set(value) :
		$Camera.current = value
		current = value


## 
@export_group("mouse")
## 
@export var mouse_follow : bool = false

##
@export_range(0., 5.) var mouse_x_sensitiveness : float = 0.1

## 
@export_range(0., 2.) var mouse_y_sensitiveness : float = 0.5


# Camera3D properies replication
@export_category("Camera3D")
@export var keep_aspect : Camera3D.KeepAspect = Camera3D.KEEP_HEIGHT
@export_flags_3d_render var cull_mask : int = 1048575
@export var environment : Environment 
@export var attributes : CameraAttributes
@export var doppler_tracking : Camera3D.DopplerTracking = Camera3D.DOPPLER_TRACKING_DISABLED
@export var projection : Camera3D.ProjectionType = Camera3D.PROJECTION_PERSPECTIVE
@export_range(1.0, 179.0, 0.1, "suffix:°") var FOV = 75.0 
@export var near := 0.05 
@export var far := 4000.0



var camera_tilt_deg := 0.
var camera_horizontal_rotation_deg := 0.


func _ready():
	_camera.top_level = true


func _physics_process(_delta):
	_update_camera_properties()
	if Engine.is_editor_hint() :
		_camera_marker.global_position = Vector3(0., 0., 1.).rotated(Vector3(1., 0., 0.), deg_to_rad(initial_dive_angle_deg)).rotated(Vector3(0., 1., 0.), deg_to_rad(-camera_horizontal_rotation_deg)) * _camera_spring_arm.spring_length + _camera_spring_arm.global_position
		pass
	_camera.global_position = _camera_marker.global_position
	_camera_offset_pivot.global_position = _camera_offset_pivot.get_parent().to_global(Vector3(pivot_offset.x, pivot_offset.y, 0.0)) 
	_camera_rotation_pivot.global_rotation_degrees.x = initial_dive_angle_deg
	_camera_rotation_pivot.global_position = global_position
	_process_tilt_input()
	_process_horizontal_rotation_input()
	_update_camera_tilt()
	_update_camera_horizontal_rotation()


func _process_horizontal_rotation_input() :
	if InputMap.has_action("tp_camera_right") and InputMap.has_action("tp_camera_left") :
		var camera_horizontal_rotation_variation = Input.get_action_strength("tp_camera_right") -  Input.get_action_strength("tp_camera_left")
		camera_horizontal_rotation_variation = camera_horizontal_rotation_variation * get_process_delta_time() * horizontal_rotation_sensitiveness
		camera_horizontal_rotation_deg += camera_horizontal_rotation_variation


func _process_tilt_input() :
	if InputMap.has_action("tp_camera_up") and InputMap.has_action("tp_camera_down") :
		var tilt_variation = Input.get_action_strength("tp_camera_up") -  Input.get_action_strength("tp_camera_down")
		tilt_variation = tilt_variation * get_process_delta_time() * tilt_sensitiveness
		camera_tilt_deg = clamp(camera_tilt_deg + tilt_variation, tilt_lower_limit_deg - initial_dive_angle_deg, tilt_upper_limit_deg - initial_dive_angle_deg)
	


func _update_camera_tilt() :
	_camera.global_rotation_degrees.x = clampf(initial_dive_angle_deg + camera_tilt_deg, tilt_lower_limit_deg, tilt_upper_limit_deg)


func _update_camera_horizontal_rotation() :
	# TODO : inverse
	_camera_rotation_pivot.global_rotation_degrees.y = camera_horizontal_rotation_deg * -1
	var vect_to_offset_pivot : Vector2 = (
		Vector2(_camera_offset_pivot.global_position.x, _camera_offset_pivot.global_position.z) 
		-
		Vector2(_camera.global_position.x, _camera.global_position.z)
		).normalized()
	_camera.global_rotation.y = -Vector2(0., -1.).angle_to(Vector2(vect_to_offset_pivot).normalized())
	



func _unhandled_input(event):
	if mouse_follow and event is InputEventMouseMotion:
		camera_horizontal_rotation_deg += event.relative.x * mouse_x_sensitiveness
		camera_tilt_deg -= event.relative.y * mouse_y_sensitiveness
		return
	
	pass


func _update_camera_properties() :
	_camera.keep_aspect = keep_aspect
	_camera.cull_mask = cull_mask
	_camera.doppler_tracking = doppler_tracking
	_camera.projection = projection
	_camera.fov = FOV
	_camera.near = near
	_camera.far = far
	if _camera.environment != environment :
		_camera.environment = environment
	if _camera.attributes != attributes :
		_camera.attributes = attributes


func get_camera() :
	return $Camera


func get_front_direction() :
	var dir : Vector3 = _camera_offset_pivot.global_position - _camera.global_position
	dir.y = 0.
	dir = dir.normalized()
	return dir

func get_back_direction() :
	return -get_front_direction()

func get_left_direction() :
	return get_front_direction().rotated(Vector3.UP, PI/2)

func get_right_direction() :
	return get_front_direction().rotated(Vector3.UP, -PI/2)
