"""Build Tokenfront's Blender source scene.

This file is executed inside Blender through the Blender MCP
`execute_blender_code` tool. It intentionally uses no network assets.
"""

import math
import os
import random

import bpy
from mathutils import Vector


ROOT = os.environ.get("TOKENFRONT_REPO_ROOT")
if not ROOT:
    raise RuntimeError(
        "TOKENFRONT_REPO_ROOT is required; invoke this file with "
        "tooling/blender_mcp_call.py --code-file."
    )
OUTPUT_DIR = os.path.join(ROOT, "assets", "blender")
BLEND_PATH = os.path.join(OUTPUT_DIR, "tokenfront_arena.blend")
RENDER_PATH = os.path.join(OUTPUT_DIR, "tokenfront_keyart.png")
GLB_PATH = os.path.join(OUTPUT_DIR, "tokenfront_arena.glb")

PALETTE = {
    "field": (0.009, 0.019, 0.022, 1.0),
    "oxide": (0.031, 0.061, 0.066, 1.0),
    "ivory": (0.888, 0.815, 0.635, 1.0),
    "amethyst": (0.357, 0.181, 1.000, 1.0),
    "cobalt": (0.051, 0.263, 1.000, 1.0),
    "volt": (0.768, 0.650, 0.045, 1.0),
    "prism": (1.000, 0.157, 0.357, 1.0),
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, metallic=0.0, roughness=0.72, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        if bsdf.inputs.get("Base Color"):
            bsdf.inputs["Base Color"].default_value = color
        if bsdf.inputs.get("Metallic"):
            bsdf.inputs["Metallic"].default_value = metallic
        if bsdf.inputs.get("Roughness"):
            bsdf.inputs["Roughness"].default_value = roughness
        if emission and bsdf.inputs.get("Emission Color"):
            bsdf.inputs["Emission Color"].default_value = color
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def cube(name, location, scale, mat, bevel=0.0, rotation=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=(0, 0, rotation))
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("Clipped corners", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
    obj.data.materials.append(mat)
    return obj


def cylinder(name, location, radius, depth, vertices, mat, rotation=0.0):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=(0, 0, rotation),
    )
    obj = bpy.context.object
    obj.name = name
    bevel = obj.modifiers.new("Token edge", "BEVEL")
    bevel.width = min(radius * 0.12, 0.035)
    bevel.segments = 1
    obj.data.materials.append(mat)
    return obj


def curve_tape(points, mat):
    curve_data = bpy.data.curves.new("Relay Tape path", "CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 3
    curve_data.bevel_depth = 0.055
    curve_data.bevel_resolution = 0
    spline = curve_data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, co in zip(spline.bezier_points, points):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new("RELAY_TAPE", curve_data)
    bpy.context.collection.objects.link(obj)
    curve_data.materials.append(mat)
    return obj


def broken_arc(name, radius, segments, mat, z=0.07):
    curve_data = bpy.data.curves.new(f"{name} path", "CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 2
    curve_data.bevel_depth = 0.026
    curve_data.bevel_resolution = 0
    for start, end in segments:
        spline = curve_data.splines.new("POLY")
        points = max(8, int((end - start) * radius * 2.0))
        spline.points.add(points - 1)
        for index, point in enumerate(spline.points):
            theta = math.radians(start + (end - start) * index / (points - 1))
            point.co = (math.cos(theta) * radius, math.sin(theta) * radius, z, 1)
    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(obj)
    curve_data.materials.append(mat)
    return obj


def planetary_limb(name, location, radius, mat):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=64,
        radius=radius,
        depth=0.035,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Soft planetary edge", "BEVEL")
    bevel.width = 0.04
    bevel.segments = 2
    return obj


def look_at(obj, target=(0, 0, 0)):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def build_scene():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    clear_scene()
    scene = bpy.context.scene
    # Blender 5.1 exposes Eevee as BLENDER_EEVEE; older 4.x builds used
    # BLENDER_EEVEE_NEXT. Prefer the value actually advertised by this build.
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1440
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.filepath = RENDER_PATH
    scene.render.image_settings.color_depth = "8"

    world = scene.world or bpy.data.worlds.new("Tokenfront World")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = PALETTE["field"]
    background.inputs["Strength"].default_value = 0.20

    field_mat = material("Battlefield Oxide", PALETTE["oxide"], roughness=0.92)
    grid_mat = material("Pressed grid", (0.073, 0.105, 0.106, 1), roughness=0.95)
    rail_mat = material("Relay Ivory", PALETTE["ivory"], metallic=0.12, roughness=0.48, emission=1.4)
    dark_metal = material("Boundary metal", (0.018, 0.030, 0.032, 1), metallic=0.7, roughness=0.55)
    void_mat = material("Planetary void", (0.004, 0.009, 0.012, 1), metallic=0.15, roughness=0.94)
    beacon_mat = material("Last Relay beacon", PALETTE["ivory"], metallic=0.34, roughness=0.48, emission=0.35)
    arc_mat = material("Broken orbit arc", PALETTE["ivory"], metallic=0.18, roughness=0.62, emission=0.22)
    faction_mats = {
        key: material(key.title(), PALETTE[key], metallic=0.28, roughness=0.54, emission=0.14)
        for key in ("amethyst", "cobalt", "volt", "prism")
    }

    cube("ARENA", (0, 0, -0.22), (8.5, 5.25, 0.22), field_mat, bevel=0.18)
    for x in range(-8, 9):
        cube(f"Grid X {x:+d}", (x, 0, 0.012), (0.012, 5.0, 0.012), grid_mat)
    for y in range(-5, 6):
        cube(f"Grid Y {y:+d}", (0, y, 0.012), (8.25, 0.012, 0.012), grid_mat)

    cylinder("LastRelayBeacon", (0, 0, 0.24), 0.34, 0.24, 8, beacon_mat, rotation=math.pi / 8)
    cylinder("LastRelayBeaconCore", (0, 0, 0.42), 0.105, 0.12, 8, beacon_mat, rotation=math.pi / 8)
    broken_arc("BrokenOrbitArc01", 1.35, ((18, 132), (194, 308)), arc_mat)
    broken_arc("BrokenOrbitArc02", 2.35, ((42, 158), (214, 334)), arc_mat)
    broken_arc("BrokenOrbitArc03", 3.45, ((2, 94), (146, 276)), arc_mat)
    planetary_limb("PlanetaryLimb", (9.5, 5.9, -0.08), 3.9, void_mat)
    node_positions = {
        "SignalNodeAmethyst": (-1.95, 0.20, "amethyst"),
        "SignalNodeCobalt": (0.70, 1.95, "cobalt"),
        "SignalNodeVolt": (2.15, -0.35, "volt"),
        "SignalNodePrism": (-0.45, -2.10, "prism"),
    }
    for node_name, (x, y, faction) in node_positions.items():
        cylinder(node_name, (x, y, 0.16), 0.115, 0.16, 6, faction_mats[faction], rotation=math.pi / 6)

    cube("North rail", (0, 5.32, 0.25), (8.75, 0.12, 0.25), dark_metal, bevel=0.06)
    cube("South rail", (0, -5.32, 0.25), (8.75, 0.12, 0.25), dark_metal, bevel=0.06)
    cube("East rail", (8.57, 0, 0.25), (0.12, 5.2, 0.25), dark_metal, bevel=0.06)
    cube("West rail", (-8.57, 0, 0.25), (0.12, 5.2, 0.25), dark_metal, bevel=0.06)

    rng = random.Random(73021)
    configs = [
        ("amethyst", (-6.2, 3.4), (0.78, -0.52), 4, math.pi / 4),
        ("cobalt", (6.2, 3.4), (-0.76, -0.54), 8, math.pi / 8),
        ("volt", (-6.2, -3.4), (0.79, 0.50), 3, math.pi / 2),
        ("prism", (6.2, -3.4), (-0.81, 0.52), 6, 0.0),
    ]
    all_units = []
    for faction_index, (name, origin, drift, sides, angle) in enumerate(configs):
        collection = bpy.data.collections.new(name.title())
        scene.collection.children.link(collection)
        mat = faction_mats[name]
        for i in range(100):
            level = i % 10 + 1
            row = i // 10
            col = i % 10
            pressure = (row / 9.0) ** 1.45
            x = origin[0] + (col - 4.5) * 0.39 + drift[0] * pressure * 3.2 + rng.uniform(-0.13, 0.13)
            y = origin[1] + (row - 4.5) * 0.37 + drift[1] * pressure * 3.0 + rng.uniform(-0.13, 0.13)
            radius = 0.135 + level * 0.0065
            height = 0.13 + level * 0.009
            obj = cylinder(
                f"{name.upper()}_{i:03d}_LV{level:02d}",
                (x, y, height / 2 + 0.04),
                radius,
                height,
                sides,
                mat,
                rotation=angle + rng.uniform(-0.2, 0.2),
            )
            for owned_collection in list(obj.users_collection):
                owned_collection.objects.unlink(obj)
            collection.objects.link(obj)
            all_units.append(obj)

        core = cylinder(
            f"{name.upper()}_RALLY",
            (origin[0], origin[1], 0.20),
            0.38,
            0.38,
            sides,
            mat,
            rotation=angle,
        )
        ring = bpy.data.curves.new(f"{name} rally ring", "CURVE")
        ring.dimensions = "2D"
        ring.bevel_depth = 0.018
        ring.bevel_resolution = 0
        ring_spline = ring.splines.new("POLY")
        ring_spline.points.add(31)
        for idx, point in enumerate(ring_spline.points):
            theta = idx / 31.0 * math.tau
            point.co = (origin[0] + math.cos(theta) * 0.62, origin[1] + math.sin(theta) * 0.62, 0.035, 1)
        ring_spline.use_cyclic_u = True
        ring_obj = bpy.data.objects.new(f"{name.upper()}_RALLY_RING", ring)
        scene.collection.objects.link(ring_obj)
        ring.materials.append(mat)

    fallen = (-1.75, 0.7, 0.14)
    successor = (2.45, -0.65, 0.18)
    curve_tape(
        [
            fallen,
            (-0.9, 1.25, 0.42),
            (0.7, -1.25, 0.65),
            successor,
        ],
        rail_mat,
    )
    cylinder("FALLEN_SIGNAL", fallen, 0.28, 0.045, 4, dark_metal, rotation=math.pi / 4)
    selected = cylinder("CONTROLLED_SIGNAL", successor, 0.24, 0.26, 4, faction_mats["amethyst"], rotation=math.pi / 4)
    cylinder("CONTROL_RING", (successor[0], successor[1], 0.045), 0.39, 0.025, 48, rail_mat)
    cube("DIRECTION_MARK", (successor[0] + 0.45, successor[1], 0.07), (0.18, 0.055, 0.028), rail_mat, bevel=0.02)

    spark_positions = [(-0.8, 0.1), (0.1, 0.4), (0.8, -0.2), (-0.2, -0.7), (1.25, 0.65)]
    for i, (x, y) in enumerate(spark_positions):
        mat = faction_mats[("amethyst", "cobalt", "volt", "prism")[i % 4]]
        cube(f"COMBAT_FLASH_{i}", (x, y, 0.28 + i * 0.035), (0.04, 0.04, 0.16), mat, rotation=i * 0.65)

    bpy.ops.object.light_add(type="AREA", location=(-4.5, -3.5, 11))
    key_light = bpy.context.object
    key_light.name = "Relay key light"
    key_light.data.energy = 1250
    key_light.data.shape = "DISK"
    key_light.data.size = 7.5
    key_light.data.color = (1.0, 0.82, 0.57)
    look_at(key_light)

    bpy.ops.object.light_add(type="AREA", location=(6.5, 4.0, 7.5))
    fill_light = bpy.context.object
    fill_light.name = "Cold faction fill"
    fill_light.data.energy = 900
    fill_light.data.size = 6.0
    fill_light.data.color = (0.26, 0.42, 1.0)
    look_at(fill_light)

    bpy.ops.object.camera_add(location=(0.0, -15.7, 18.8))
    camera = bpy.context.object
    camera.name = "TACTICAL_CAMERA"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 18.8
    camera.data.lens = 50
    look_at(camera, (0, 0, 0))
    scene.camera = camera

    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.filepath = RENDER_PATH
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)
    try:
        bpy.ops.export_scene.gltf(filepath=GLB_PATH, export_format="GLB", export_cameras=False, export_lights=False)
    except Exception as exc:
        print(f"GLB export skipped: {exc}")
    print(f"TOKENFRONT_SCENE_READY blend={BLEND_PATH} render={RENDER_PATH} objects={len(bpy.data.objects)}")


build_scene()
