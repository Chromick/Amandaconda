"""
Importa FBX de rolamento (Mixamo / Quaternius) para o combate.

1) Baixe no Mixamo: "Standing Dive Forward Roll" ou "Falling To Roll"
   - Skeleton: Y Bot (depois retarget) OU baixe com UE5 Mannequin se disponivel
2) Salve o FBX em:
   D:/AmandacondaUE/Content/Amandaconda/Import/roll_forward.fbx
3) No Output Log (Play PARADO):
   py import_roll_fbx.py
4) Recarregue combate:
   py reload_hud_combat.py
"""

from __future__ import annotations

import unreal

FBX_PATH = "/Game/Amandaconda/Import/roll_forward"
DEST = "/Game/Amandaconda/Combat/Anims/AS_Roll_Forward"
SRC_ON_DISK = unreal.Paths.project_content_dir() + "Amandaconda/Import/roll_forward.fbx"


def _log(msg: str) -> None:
    unreal.log(f"[AMANDACONDA] {msg}")
    print(f"[AMANDACONDA] {msg}")


def main() -> None:
    # se ja existe, ok
    existing = unreal.load_asset(DEST)
    if existing:
        _log(f"ja existe: {DEST}")
        return

    disk = SRC_ON_DISK.replace("/", "\\")
    if not unreal.Paths.file_exists(disk):
        _log(f"FBX nao encontrado: {disk}")
        _log("Coloque roll_forward.fbx em Content/Amandaconda/Import/ e rode de novo.")
        return

    task = unreal.AssetImportTask()
    task.filename = disk
    task.destination_path = "/Game/Amandaconda/Combat/Anims"
    task.destination_name = "AS_Roll_Forward"
    task.replace_existing = True
    task.automated = True
    task.save = True

    try:
        options = unreal.FbxImportUI()
        options.import_mesh = False
        options.import_as_skeletal = False
        options.import_animations = True
        options.import_materials = False
        options.import_textures = False
        options.mesh_type_to_import = unreal.FBXImportType.FBXIT_ANIMATION
        try:
            options.set_editor_property("automated_import_should_detect_type", False)
        except Exception:
            pass
        # skeleton do mannequin UE5
        sk = unreal.load_asset("/Game/Characters/Mannequins/Meshes/SK_Mannequin")
        if not sk:
            sk = unreal.load_asset(
                "/Game/Characters/Mannequins/Rigs/SK_Mannequin"
            )
        if sk:
            try:
                options.skeleton = sk
            except Exception:
                pass
            try:
                options.set_editor_property("skeleton", sk)
            except Exception:
                pass
        task.options = options
    except Exception as exc:
        _log(f"opcoes FBX: {exc} (seguindo default)")

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    imported = unreal.load_asset(DEST)
    if imported:
        _log(f"import OK → {DEST}")
        _log("Agora: py reload_hud_combat.py  e teste Ctrl no PIE")
    else:
        # as vezes o nome fica diferente
        _log("import terminou — confira Content/Amandaconda/Combat/Anims/")
        for a in unreal.EditorAssetLibrary.list_assets(
            "/Game/Amandaconda/Combat/Anims", True, False
        ):
            _log(f"  asset: {a}")


if __name__ == "__main__":
    main()
