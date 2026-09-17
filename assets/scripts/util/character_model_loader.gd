class_name CharacterModelLoader
## CharacterModelLoader
## أداة مشتركة تستخدمها كل الشخصيات (Zade، Nyra، المارة، أعضاء العصابات، سكان الجزر)
## عشان تحمّل نموذج بشري حقيقي، تطبّق الجلد الصحيح، وتدمج حركات المشي/الجري/القفز
## تلقائياً وقت التشغيل.

const DEFAULT_ANIM_NAMES: Array[String] = ["idle", "run", "jump"]
const FBX_SCALE_CORRECTION: float = 0.01


static func load_character(
	model_root: Node3D,
	model_path: String,
	skin_path: String = "",
	fallback_color: Color = Color.WHITE,
	anim_names: Array[String] = DEFAULT_ANIM_NAMES,
	animation_library_path: String = ""
) -> AnimationPlayer:
	if model_path == "" or not ResourceLoader.exists(model_path):
		_add_fallback_capsule(model_root, fallback_color)
		return null

	var model_scene: PackedScene = load(model_path)
	if model_scene == null:
		_add_fallback_capsule(model_root, fallback_color)
		return null

	var instance := model_scene.instantiate()
	model_root.add_child(instance)

	if skin_path != "" and ResourceLoader.exists(skin_path):
		var texture: Texture2D = load(skin_path)
		_apply_skin(instance, texture)

	var anim_player: AnimationPlayer = _find_animation_player(instance)
	if anim_player == null:
		anim_player = _create_animation_player(instance)

	if anim_player == null:
		return null

	if animation_library_path != "" and ResourceLoader.exists(animation_library_path):
		_merge_full_library(anim_player, animation_library_path)
	else:
		_merge_sibling_animations(anim_player, model_path, anim_names)
	return anim_player


static func _merge_full_library(anim_player: AnimationPlayer, library_path: String) -> void:
	var lib_scene = load(library_path)
	if lib_scene == null:
		return
	var lib_instance = lib_scene.instantiate()
	var source_player: AnimationPlayer = _find_animation_player(lib_instance)
	if source_player == null:
		lib_instance.queue_free()
		return

	var target_lib: AnimationLibrary
	if anim_player.has_animation_library(""):
		target_lib = anim_player.get_animation_library("")
	else:
		target_lib = AnimationLibrary.new()
		anim_player.add_animation_library("", target_lib)

	for lib_name in source_player.get_animation_library_list():
		var source_lib: AnimationLibrary = source_player.get_animation_library(lib_name)
		for a_name in source_lib.get_animation_list():
			if not target_lib.has_animation(a_name):
				target_lib.add_animation(a_name, source_lib.get_animation(a_name))

	var aliases := {"idle": "Idle", "run": "Jog_Fwd", "jump": "Jump"}
	for alias in aliases.keys():
		var real_name: String = aliases[alias]
		if target_lib.has_animation(real_name) and not target_lib.has_animation(alias):
			target_lib.add_animation(alias, target_lib.get_animation(real_name))

	lib_instance.queue_free()


static func _create_animation_player(instance: Node) -> AnimationPlayer:
	var skeleton: Skeleton3D = _find_skeleton(instance)
	if skeleton == null:
		return null
	var container: Node = skeleton.get_parent()
	var parent_for_player: Node = container.get_parent() if container else null
	if parent_for_player == null:
		parent_for_player = container if container else skeleton
	var anim_player := AnimationPlayer.new()
	parent_for_player.add_child(anim_player)
	return anim_player


static func _find_node_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result: Node = _find_node_named(child, target_name)
		if result:
			return result
	return null


static func attach_outfit(character_instance: Node, outfit_path: String) -> void:
	if outfit_path == "" or not ResourceLoader.exists(outfit_path):
		return
	var outfit_scene: PackedScene = load(outfit_path)
	if outfit_scene == null:
		return
	var outfit_instance := outfit_scene.instantiate()

	var target_skeleton: Skeleton3D = _find_skeleton(character_instance)
	if target_skeleton == null:
		outfit_instance.queue_free()
		return

	var meshes: Array = []
	_collect_meshes(outfit_instance, meshes)
	for mesh in meshes:
		mesh.get_parent().remove_child(mesh)
		target_skeleton.add_child(mesh)
		mesh.skeleton = NodePath(".")

	outfit_instance.queue_free()


static func _collect_meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_meshes(child, result)


static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result: Skeleton3D = _find_skeleton(child)
		if result:
			return result
	return null


static func _merge_sibling_animations(anim_player: AnimationPlayer, model_path: String, anim_names: Array[String]) -> void:
	var base_dir: String = model_path.get_base_dir()
	var lib: AnimationLibrary

	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)

	for anim_name in anim_names:
		if lib.has_animation(anim_name):
			continue

		var anim_fbx_path: String = base_dir.path_join(anim_name + ".fbx")
		if not ResourceLoader.exists(anim_fbx_path):
			continue

		var anim_scene_res = load(anim_fbx_path)
		if anim_scene_res == null:
			continue

		var anim_instance = anim_scene_res.instantiate()
		var source_player: AnimationPlayer = _find_animation_player(anim_instance)
		if source_player:
			for lib_name in source_player.get_animation_library_list():
				var source_lib: AnimationLibrary = source_player.get_animation_library(lib_name)
				for a_name in source_lib.get_animation_list():
					if not lib.has_animation(anim_name):
						lib.add_animation(anim_name, source_lib.get_animation(a_name))
		anim_instance.queue_free()


static func _apply_skin(node: Node, texture: Texture2D) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = texture
		node.material_override = mat
	for child in node.get_children():
		_apply_skin(child, texture)


static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result:
			return result
	return null


static func _add_fallback_capsule(model_root: Node3D, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh_instance.mesh = capsule
	mesh_instance.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	model_root.add_child(mesh_instance)
