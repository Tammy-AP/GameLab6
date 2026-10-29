"""
Run in Blender (background):
  blender.exe -b Tools/blender/character.blend --python Tools/blender/export_mixamo.py -- <out_dir> <face_texture.png>

Mixamo does not read textures embedded inside an FBX, so this writes the model and
its face texture as separate files and zips them together:
  character_for_mixamo_obj.zip  (OBJ + MTL + PNG)  <- try this first
  character_for_mixamo_fbx.zip  (FBX + PNG)
"""
import os
import shutil
import sys
import zipfile

import bpy

out_dir, face_png = sys.argv[sys.argv.index("--") + 1:]
tmp = os.path.join(out_dir, "_tmp")
shutil.rmtree(tmp, ignore_errors=True)
os.makedirs(tmp)

body = bpy.data.objects["Character_Body"]
for o in bpy.context.view_layer.objects:
    o.select_set(False)
body.select_set(True)
bpy.context.view_layer.objects.active = body

# point the face image at a plain file next to the model
tex_path = os.path.join(tmp, "face_texture.png")
shutil.copyfile(face_png, tex_path)
for img in bpy.data.images:
    if "face" in img.name.lower():
        if img.packed_file:
            img.unpack(method="REMOVE")
        img.filepath = tex_path
        img.reload()

bpy.ops.wm.obj_export(
    filepath=os.path.join(tmp, "character.obj"), export_selected_objects=True,
    export_materials=True, path_mode="STRIP", forward_axis="NEGATIVE_Z", up_axis="Y",
    apply_modifiers=True, export_uv=True, export_normals=True, export_animation=False)

def linear_to_srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


# Blender writes linear colours; Mixamo shows Kd as sRGB (too dark), so convert them
mtl_path = os.path.join(tmp, "character.mtl")
lines = []
for line in open(mtl_path, encoding="utf-8"):
    if line.startswith("Kd "):
        r, g, b = (linear_to_srgb(float(v)) for v in line.split()[1:4])
        line = "Kd %.6f %.6f %.6f\n" % (r, g, b)
    lines.append(line)
open(mtl_path, "w", encoding="utf-8").writelines(lines)

bpy.ops.export_scene.fbx(
    filepath=os.path.join(tmp, "character.fbx"), use_selection=True, object_types={"MESH"},
    use_mesh_modifiers=True, path_mode="STRIP", embed_textures=False, add_leaf_bones=False,
    bake_anim=False, axis_forward="-Z", axis_up="Y")


def make_zip(name, files):
    path = os.path.join(out_dir, name)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            z.write(os.path.join(tmp, f), f)
    print("[mixamo] wrote", path, files)


make_zip("character_for_mixamo_obj.zip", ["character.obj", "character.mtl", "face_texture.png"])
make_zip("character_for_mixamo_fbx.zip", ["character.fbx", "face_texture.png"])
shutil.rmtree(tmp, ignore_errors=True)
