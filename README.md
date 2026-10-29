# Skybound Bot – แบบฝึกหัดที่ 6 First 3D Character (Godot 4.7)

ต่อยอดจากเกมแบบฝึกหัดที่ 5 (Skybound Bot) โดยเปลี่ยน **Player เป็นตัวละครที่สร้างเอง**
ใส่โครงกระดูกแบบ Mixamo แล้วนำ Animation จาก
[Godot4-OpenAnimationLibraries](https://github.com/catprisbrey/Godot4-OpenAnimationLibraries)
(`MeleeLib.res` + `ShooterLib.res`) มาใช้ผ่าน `Mixamo BoneMap.tres`
และเพิ่มฉาก **Character Demo** สำหรับโชว์ท่าทางต่าง ๆ

- เล่นบนเว็บ: _(ใส่ลิงก์ GitHub Pages)_
- หน้าเมนู: `Enter / Space` = เล่นเกม, `C` หรือปุ่ม **Character Demo** = ดูท่าทางตัวละคร

![Character Demo](Screenshots/4f_demo_slash.png)

## ขั้นตอนที่ทำ

### 1. สร้างโมเดลตัวละคร + Blender
- รูปทรงโมเดลสร้างด้วยสคริปต์ Python `Tools/build_character.py`
  ตัวละคร low-poly: หัว + ผม, เสื้อ, ผ้าพันคอ, กางเกง, รองเท้า, มือพร้อมนิ้ว (ประมาณ 6,000 สามเหลี่ยม)
- ใบหน้าเป็นภาพการ์ตูนวาดเป็น texture: `Assets/Characters/face_texture.png`
- ผลลัพธ์คือ `Assets/Characters/player.glb`
  (สร้างใหม่ได้ด้วย `python Tools/build_character.py` ต้องมี numpy และ Pillow)
- นำเข้า **Blender 5.2** (แบบ portable) ด้วย `Tools/blender/blender_capture.py`
  ตรวจ mesh / UV ใบหน้า / rig ใน Pose Mode, บันทึก `Tools/blender/character.blend`
  และ export ไฟล์สำหรับ Mixamo (`Tools/blender/export_mixamo.py`)
  ภาพหน้าจอ: `Screenshots/2a`–`2d`

### 2. Rig แบบ Mixamo
- ไฟล์สำหรับอัปโหลดเข้า [mixamo.com](https://www.mixamo.com/): `MixamoUpload/character_for_mixamo_obj.zip`
  (OBJ + MTL + ภาพใบหน้า, mesh อย่างเดียว ท่า T-pose) หรือ `character_for_mixamo_fbx.zip`
  ต้องอัปโหลดเป็น .zip ที่มีภาพแยกไว้ เพราะ Mixamo ไม่อ่าน texture ที่ฝังอยู่ใน FBX
- ตัวละครที่ใช้ในเกมมีโครงกระดูก 65 bones ตั้งชื่อเหมือน Mixamo (`mixamorig_Hips`, `mixamorig_Spine` ... รวมนิ้วมือ)
  พร้อม skin weights สร้างในสคริปต์เดียวกัน จึงใช้ `Mixamo BoneMap.tres` ได้ตรง ๆ
- มีอนิเมชัน `TPose` 1 อัน (ตาม README ของ OpenAnimationLibraries ที่ต้องมีอย่างน้อย 1 อนิเมชัน)

### 3. นำเข้า Godot + Retarget
- `player.glb` → Advanced Import → `Armature/Skeleton3D` → **Retarget > Bone Map = `Assets/AnimLibs/Mixamo BoneMap.tres`**
  (ตั้งไว้ใน `Assets/Characters/player.glb.import`)
- Godot เปลี่ยนชื่อ bones เป็นแบบ Humanoid (Hips, Spine, Chest, ...) และตั้งชื่อ skeleton เป็น `%GeneralSkeleton`
  ทำให้ใช้ `MeleeLib.res` และ `ShooterLib.res` ได้ทันที (รวมกว่า 300 ท่า)

### 4. ใช้งานในเกม
- **Player ในเกมข้อ 5**: `Scenes/player.tscn` → โหนด **Model** (`Scripts/character_model.gd`)
  โหลดตัวละคร + เพิ่ม animation library แล้วจับคู่ท่า:
  | เกมเรียก | Animation ที่ใช้ |
  |---|---|
  | Idle | `ShooterLib/idle` |
  | Run | `MeleeLib/Sprint` |
  | Jump → Fall | `MeleeLib/Jump` → `MeleeLib/LightFalling` |
  | Flip (กระโดดสองชั้น) | `MeleeLib/Jump` + หมุนตัว 360° |
- **Character Demo**: `Scenes/Demo/character_demo.tscn` (`Scripts/character_demo.gd`)
  ปุ่มเลือกท่า 61 ท่า แบ่ง 4 หมวด Basic / Melee / Shooter / Fun, มีอาวุธติดมือด้วย `BoneAttachment3D`
  (ดาบ, โล่, ดาบใหญ่, ปืนไรเฟิล, ปืนพก, ระเบิด, ขวดยา), Auto Play, Loop, ปรับความเร็ว, หมุนกล้องด้วยเมาส์

## วิธีเปิดโปรเจกต์
1. เปิด Godot 4.7 → **Import** → เลือก `project.godot`
2. กด **F5** (Main Scene = หน้าเมนู)

## วิธีเล่น
| ปุ่ม | การทำงาน |
|---|---|
| W A S D / ลูกศร | เดิน |
| Space | กระโดด (กดซ้ำกลางอากาศ = Flip กระโดดสองชั้น) |
| เมาส์ หรือ Q / E | หมุนกล้อง |
| R | เริ่มด่านใหม่ |
| Esc | แสดง/ซ่อนเมาส์ (ในฉาก Demo = กลับเมนู) |

เป้าหมาย: หลบกับดัก เก็บ **เหรียญให้ครบ** แล้วเข้า **ประตู** ไปด่านต่อไป
มีหัวใจ 3 ดวง ชนกับดัก/ตกเหวเสียหัวใจ 1 ดวง หมดหัวใจ = เริ่มด่านใหม่

ฉาก Character Demo: คลิกปุ่มท่าทาง, ลากเมาส์ = หมุนกล้อง, ล้อเมาส์ = ซูม, A / D = ท่าก่อนหน้า/ถัดไป, Space = เล่นซ้ำ

## ฉากในเกม
- `Scenes/Menu/main_menu.tscn` – หน้าเมนู
- `Scenes/Levels/level_01.tscn` – **Sunny Skylands**
- `Scenes/Levels/level_02.tscn` – **Ember Ruins**
- `Scenes/Menu/win_screen.tscn` – หน้าจบ
- `Scenes/Demo/character_demo.tscn` – **Character Demo** (ใหม่ในข้อ 6)

## Export เป็น Web
- Preset `Web` (ไม่ใช้ threads จึงเปิดบน GitHub Pages ได้เลย)
- คำสั่ง: `Godot_v4.7-stable_win64.exe --headless --path . --export-release "Web" build/web/index.html`

## ไฟล์สำคัญ
- `Tools/build_character.py` – สร้างโมเดล + rig + texture ใบหน้า
- `Tools/blender/` – สคริปต์ Blender + `character.blend`
- `MixamoUpload/*.zip` – ไฟล์สำหรับอัปโหลดเข้า Mixamo
- `Assets/Characters/player.glb` (+ `.import` ที่ตั้ง Bone Map ไว้)
- `Assets/AnimLibs/` – `Mixamo BoneMap.tres`, `MeleeLib.res`, `ShooterLib.res`
- `Scripts/character_model.gd` – โหลดตัวละคร/อนิเมชันให้ Player
- `Scripts/character_demo.gd` – ฉาก Demo
- `Screenshots/` – ภาพหน้าจอ Blender, Godot Editor และตอนเล่น

## เครดิต
- Animation libraries + Mixamo bone map: [Godot4-OpenAnimationLibraries](https://github.com/catprisbrey/Godot4-OpenAnimationLibraries) โดย catprisbrey
- 3D Platformer Starter Kit โดย Silver Demon Studios (CC0) – โค้ดควบคุมผู้เล่นต้นแบบ (แบบฝึกหัดที่ 5)
- ฉาก, เสียง และตัวละครสร้างเองทั้งหมด
