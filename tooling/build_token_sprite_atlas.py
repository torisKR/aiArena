"""Render Tokenfront's four-faction runtime sprite atlas through Blender MCP.

The output is a transparent 4x1 atlas. Each 64x64 cell contains exactly one
top-down tactical token in faction order: Amethyst, Cobalt, Volt, Prism.
"""

import json
import math
import os

import bpy
from mathutils import Vector


ROOT = "/Users/toris/projects/aiArena"
IMAGE_DIR = os.path.join(ROOT, "assets", "images")
BLENDER_DIR = os.path.join(ROOT, "assets", "blender")
ATLAS_PATH = os.path.join(IMAGE_DIR, "tokenfront_token_atlas.png")
MANIFEST_PATH = os.path.join(IMAGE_DIR, "tokenfront_token_atlas.json")
BLEND_PATH = os.path.join(BLENDER_DIR, "tokenfront_token_atlas.blend")

CELL_SIZE = 64
FACTIONS = (
    ("amethyst", 4, math.pi / 4, (0.357, 0.181, 1.000, 1.0)),
    ("cobalt", 4, 0.0, (0.051, 0.263, 1.000, 1.0)),
    ("volt", 3, math.pi / 2, (0.768, 0.650, 0.045, 1.0)),
    ("prism", 6, 0.0, (1.000, 0.157, 0.357, 1.0)),
)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, *, metallic=0.0, roughness=0.7, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def token(name, x, vertices, rotation, color, outline_mat, core_mat):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=1.14,
        depth=0.28,
        location=(x, 0, 0.0),
        rotation=(0, 0, rotation),
    )
    outline = bpy.context.object
    outline.name = f"{name.upper()}_OUTLINE"
    outline.data.materials.append(outline_mat)
    bevel = outline.modifiers.new("Clipped outline", "BEVEL")
    bevel.width = 0.08
    bevel.segments = 1

    faction_mat = material(
        name.title(),
        color,
        metallic=0.24,
        roughness=0.54,
        emission=0.10,
    )
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=0.95,
        depth=0.34,
        location=(x, 0, 0.24),
        rotation=(0, 0, rotation),
    )
    body = bpy.context.object
    body.name = f"{name.upper()}_BODY"
    body.data.materials.append(faction_mat)
    bevel = body.modifiers.new("Clipped body", "BEVEL")
    bevel.width = 0.10
    bevel.segments = 1

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=4,
        radius=0.22,
        depth=0.10,
        location=(x, 0, 0.48),
        rotation=(0, 0, math.pi / 4),
    )
    core = bpy.context.object
    core.name = f"{name.upper()}_CORE"
    core.data.materials.append(core_mat)


def look_at(obj, target=(0, 0, 0)):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def build_atlas():
    os.makedirs(IMAGE_DIR, exist_ok=True)
    os.makedirs(BLENDER_DIR, exist_ok=True)
    clear_scene()

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = CELL_SIZE * len(FACTIONS)
    scene.render.resolution_y = CELL_SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.render.filepath = ATLAS_PATH
    scene.render.filter_size = 0.01

    outline_mat = material(
        "Battlefield Outline",
        (0.010, 0.018, 0.020, 1.0),
        metallic=0.14,
        roughness=0.62,
    )
    core_mat = material(
        "Relay Ivory Core",
        (0.89, 0.84, 0.68, 1.0),
        metallic=0.18,
        roughness=0.52,
        emission=0.20,
    )

    spacing = 3.4
    start_x = -spacing * (len(FACTIONS) - 1) / 2
    for index, (name, vertices, rotation, color) in enumerate(FACTIONS):
        token(
            name,
            start_x + index * spacing,
            vertices,
            rotation,
            color,
            outline_mat,
            core_mat,
        )

    bpy.ops.object.light_add(type="AREA", location=(-4.5, -5.0, 10.0))
    key = bpy.context.object
    key.name = "Atlas key light"
    key.data.energy = 900
    key.data.shape = "RECTANGLE"
    key.data.size = 11.0
    key.data.size_y = 4.0
    key.data.color = (1.0, 0.86, 0.64)
    look_at(key)

    bpy.ops.object.light_add(type="AREA", location=(5.0, 3.5, 7.0))
    fill = bpy.context.object
    fill.name = "Atlas cool fill"
    fill.data.energy = 520
    fill.data.size = 8.0
    fill.data.color = (0.30, 0.42, 1.0)
    look_at(fill)

    bpy.ops.object.camera_add(location=(0.0, -8.8, 12.0))
    camera = bpy.context.object
    camera.name = "ATLAS_CAMERA"
    camera.data.type = "ORTHO"
    # Blender's orthographic scale spans the horizontal sensor. At 4:1 this
    # yields a 3.4-unit-high strip and one 3.4-unit-wide cell per token.
    camera.data.ortho_scale = 13.6
    look_at(camera, (0, 0, 0.12))
    scene.camera = camera

    world = scene.world or bpy.data.worlds.new("Transparent Atlas World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (
        0.009,
        0.019,
        0.022,
        1.0,
    )
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.15

    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)

    manifest = {
        "version": 1,
        "image": "tokenfront_token_atlas.png",
        "cellSize": CELL_SIZE,
        "frames": {
            name: {
                "x": index * CELL_SIZE,
                "y": 0,
                "width": CELL_SIZE,
                "height": CELL_SIZE,
            }
            for index, (name, _, _, _) in enumerate(FACTIONS)
        },
    }
    with open(MANIFEST_PATH, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")

    print(
        "TOKEN_ATLAS_READY "
        f"render={ATLAS_PATH} manifest={MANIFEST_PATH} blend={BLEND_PATH}"
    )


build_atlas()
