"""Build the canonical Tokenfront combat-token sprite reference in Blender.

This script is executed inside Blender through Blender MCP.  It produces a
small, full-body, top-down token on a flat green chroma background so the
sprite-gen component-row pipeline can own deterministic alpha extraction and
atlas composition.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.environ.get("TOKENFRONT_REPO_ROOT")
if not ROOT:
    raise RuntimeError(
        "TOKENFRONT_REPO_ROOT is required; invoke this file with "
        "tooling/blender_mcp_call.py --code-file."
    )
OUTPUT_DIR = os.path.join(ROOT, "assets", "generated", "sprites")
BASE_PATH = os.path.join(OUTPUT_DIR, "token-signal-base.png")
BLEND_PATH = os.path.join(ROOT, "assets", "blender", "token_sprite_base.blend")


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


def material(name, color, *, metallic=0.0, roughness=0.72, emission=0.0):
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


def look_at(obj, target=(0, 0, 0)):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def cylinder(name, radius, depth, z, vertices, mat, rotation=0.0):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=(0, 0, z),
        rotation=(0, 0, rotation),
    )
    obj = bpy.context.object
    obj.name = name
    bevel = obj.modifiers.new("Pixel clipped bevel", "BEVEL")
    bevel.width = 0.10
    bevel.segments = 1
    obj.data.materials.append(mat)
    return obj


def cube(name, location, scale, mat, rotation=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=(0, 0, rotation))
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Pixel clipped bevel", "BEVEL")
    bevel.width = 0.07
    bevel.segments = 1
    obj.data.materials.append(mat)
    return obj


def build_sprite_base():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(BLEND_PATH), exist_ok=True)
    clear_scene()

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 96
    scene.render.resolution_y = 96
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.filepath = BASE_PATH
    scene.render.filter_size = 0.01

    chroma = (0.0, 1.0, 0.0, 1.0)
    ivory = (0.89, 0.84, 0.68, 1.0)
    oxide = (0.018, 0.030, 0.032, 1.0)
    amethyst = (0.37, 0.19, 1.0, 1.0)

    chroma_mat = material("Chroma Green", chroma, roughness=1.0, emission=1.0)
    outline_mat = material("Field Outline", oxide, metallic=0.12, roughness=0.58)
    ivory_mat = material("Relay Ivory", ivory, metallic=0.20, roughness=0.52)
    signal_mat = material(
        "Amethyst Signal",
        amethyst,
        metallic=0.24,
        roughness=0.48,
        emission=0.10,
    )

    # A flat emissive plane gives the extraction pipeline an exact, shadow-free
    # chroma field while the stacked meshes retain a readable tactical depth.
    cube("CHROMA_FIELD", (0, 0, -0.35), (7.5, 7.5, 0.06), chroma_mat)
    cylinder("TOKEN_OUTLINE", 1.32, 0.36, 0.01, 4, outline_mat, math.pi / 4)
    cylinder("TOKEN_BODY", 1.15, 0.42, 0.23, 4, ivory_mat, math.pi / 4)
    cylinder("SIGNAL_CORE", 0.47, 0.14, 0.51, 4, signal_mat, math.pi / 4)
    cube("DIRECTION_NIB", (0, 1.24, 0.35), (0.18, 0.34, 0.13), ivory_mat)

    bpy.ops.object.light_add(type="AREA", location=(-3.2, -4.0, 8.0))
    key = bpy.context.object
    key.name = "Ivory key light"
    key.data.energy = 620
    key.data.shape = "DISK"
    key.data.size = 5.5
    key.data.color = (1.0, 0.88, 0.68)
    look_at(key)

    bpy.ops.object.light_add(type="AREA", location=(4.0, 2.5, 6.0))
    fill = bpy.context.object
    fill.name = "Cold fill light"
    fill.data.energy = 320
    fill.data.size = 4.0
    fill.data.color = (0.34, 0.46, 1.0)
    look_at(fill)

    bpy.ops.object.camera_add(location=(0.0, -6.4, 8.7))
    camera = bpy.context.object
    camera.name = "SPRITE_CAMERA"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4.4
    look_at(camera, (0, 0, 0.18))
    scene.camera = camera

    world = scene.world or bpy.data.worlds.new("Token Sprite World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = chroma
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0

    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)
    print(
        "TOKEN_SPRITE_BASE_READY "
        f"render={BASE_PATH} blend={BLEND_PATH} objects={len(bpy.data.objects)}"
    )


build_sprite_base()
