"""
Run inside Blender (GUI):
  blender.exe <empty.blend> --python Tools/blender/blender_capture.py -- <player.glb> <out_dir> <mixamo.fbx> <character.blend>

Imports the character (player.glb) into Blender, takes real Blender screenshots
(Object mode, Edit mode, UV Editing with the face texture, Pose mode),
exports a mesh-only FBX for uploading to mixamo.com, saves a .blend, then quits.
"""
import math
import os
import sys

import bpy
from mathutils import Euler, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
GLB, OUT_DIR, FBX, BLEND = argv
os.makedirs(OUT_DIR, exist_ok=True)


def win():
    return bpy.context.window_manager.windows[0]


def area_of(kind="VIEW_3D"):
    w = win()
    for a in w.screen.areas:
        if a.type == kind:
            return w, a, next(r for r in a.regions if r.type == "WINDOW")
    return w, None, None


def ctx(kind="VIEW_3D"):
    w, a, r = area_of(kind)
    if a is None:
        return bpy.context.temp_override(window=w, screen=w.screen)
    return bpy.context.temp_override(window=w, screen=w.screen, area=a, region=r)


def shot(name):
    w = win()
    with bpy.context.temp_override(window=w, screen=w.screen):
        bpy.ops.screen.screenshot(filepath=os.path.join(OUT_DIR, name), check_existing=False)
    print("[capture] saved", name)


def objects():
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    body = next(o for o in bpy.data.objects if o.type == "MESH")
    return arm, body


def select_only(obj):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def frame_view(dist=3.4, yaw=-28.0, z=0.95):
    for a in win().screen.areas:
        if a.type == "VIEW_3D":
            sp = a.spaces.active
            sp.shading.type = "MATERIAL"
            sp.overlay.show_floor = True
            r3d = sp.region_3d
            r3d.view_perspective = "PERSP"
            r3d.view_location = (0.0, 0.0, z)
            r3d.view_distance = dist
            r3d.view_rotation = Euler((math.radians(80), 0.0, math.radians(yaw)), "XYZ").to_quaternion()


# ---------------------------------------------------------------- steps

def step_import():
    with ctx():
        for o in list(bpy.data.objects):
            if o.type == "MESH":
                bpy.data.objects.remove(o, do_unlink=True)
        bpy.ops.import_scene.gltf(filepath=GLB, bone_heuristic="TEMPERANCE")
    arm, body = objects()
    arm.name = "Character_Rig"
    body.name = "Character_Body"
    arm.show_in_front = True
    arm.data.display_type = "OCTAHEDRAL"
    with ctx():
        select_only(body)
    frame_view()
    return 12.0  # give EEVEE time to compile the material preview shaders


def step_object_shot():
    shot("2a_blender_character.png")
    _, body = objects()
    with ctx():
        select_only(body)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="DESELECT")
        idx = next(i for i, m in enumerate(body.data.materials) if m and m.name == "Hair")
        body.active_material_index = idx
        bpy.ops.object.material_slot_select()
    frame_view(dist=2.4, yaw=-20.0, z=1.2)
    return 3.0


def step_edit_shot():
    shot("2b_blender_edit_mode.png")
    with ctx():
        bpy.ops.object.mode_set(mode="OBJECT")
    ws = bpy.data.workspaces.get("UV Editing")
    if ws:
        win().workspace = ws
    return 2.0


def step_uv_setup():
    _, body = objects()
    try:
        with ctx():
            select_only(body)
            if body.mode != "EDIT":
                bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="DESELECT")
            idx = next(i for i, m in enumerate(body.data.materials) if m and m.name == "Face")
            body.active_material_index = idx
            bpy.ops.object.material_slot_select()
        img = next((im for im in bpy.data.images if "face" in im.name.lower()), None)
        for a in win().screen.areas:
            if a.type == "IMAGE_EDITOR" and img:
                sp = a.spaces.active
                sp.image = img
                for attr, val in (("uv_face_opacity", 0.0), ("uv_opacity", 0.35)):
                    for owner in (sp.uv_editor, getattr(sp, "overlay", None)):
                        if owner is not None and hasattr(owner, attr):
                            setattr(owner, attr, val)
            if a.type == "VIEW_3D":
                sp = a.spaces.active
                sp.shading.type = "MATERIAL"
                r3d = sp.region_3d
                r3d.view_perspective = "PERSP"
                r3d.view_location = (0.0, 0.0, 1.6)
                r3d.view_distance = 1.1
                r3d.view_rotation = Euler((math.radians(85), 0.0, math.radians(-20)), "XYZ").to_quaternion()
        with ctx("IMAGE_EDITOR"):
            bpy.ops.image.view_all(fit_view=True)
    except Exception as e:  # the UV shot is a bonus; never stop the run for it
        print("[capture] uv setup skipped:", e)
    return 2.5


def step_uv_shot():
    shot("2c_blender_uv_face_texture.png")
    _, body = objects()
    with ctx():
        if body.mode != "OBJECT":
            bpy.ops.object.mode_set(mode="OBJECT")
    ws = bpy.data.workspaces.get("Layout")
    if ws:
        win().workspace = ws
    return 1.5


def step_export():
    arm, body = objects()
    with ctx():
        select_only(body)
        bpy.ops.export_scene.fbx(
            filepath=FBX, use_selection=True, object_types={"MESH"}, use_mesh_modifiers=True,
            path_mode="COPY", embed_textures=True, add_leaf_bones=False, bake_anim=False,
            axis_forward="-Z", axis_up="Y")
        print("[capture] exported", FBX)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, copy=True)
        print("[capture] saved", BLEND)
        select_only(arm)
        bpy.ops.object.mode_set(mode="POSE")
    pose_wave(arm)
    frame_view(dist=3.4, yaw=-32.0)
    return 2.5


def pose_wave(arm):
    """Rotate a few bones in armature space so the shot shows the rig working."""
    def rot(bone_name, axis, deg):
        pb = arm.pose.bones.get("mixamorig_" + bone_name)
        if pb is None:
            return
        head = pb.head.copy()
        r = Matrix.Rotation(math.radians(deg), 4, axis)
        pb.matrix = Matrix.Translation(head) @ r @ Matrix.Translation(-head) @ pb.matrix
        bpy.context.view_layer.update()
    rot("LeftArm", "Y", 68)        # left arm down
    rot("LeftForeArm", "Z", 20)
    rot("RightArm", "Y", 55)       # right arm up (wave)
    rot("RightForeArm", "Y", 55)
    rot("Head", "Y", -10)
    rot("Spine1", "Y", 4)
    rot("LeftUpLeg", "X", -12)
    rot("LeftLeg", "X", 18)
    for pb in arm.pose.bones:
        sel = pb.name in ("mixamorig_RightArm", "mixamorig_RightForeArm")
        for owner in (pb, pb.bone):  # Blender 5 moved bone selection to the pose bone
            if hasattr(owner, "select"):
                owner.select = sel
                break


def step_pose_shot():
    shot("2d_blender_pose_mode.png")
    return 1.0


def step_quit():
    bpy.ops.wm.quit_blender()
    return None


STEPS = [step_import, step_object_shot, step_edit_shot, step_uv_setup, step_uv_shot,
         step_export, step_pose_shot, step_quit]


def runner():
    if not STEPS:
        return None
    fn = STEPS.pop(0)
    try:
        delay = fn()
    except Exception as e:
        import traceback
        traceback.print_exc()
        print("[capture] step failed:", fn.__name__, e)
        delay = 1.0
    return delay if STEPS else None


bpy.app.timers.register(runner, first_interval=5.0)
