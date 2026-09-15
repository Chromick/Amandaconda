"""No Output Log do Unreal:  py fix_save_warning.py"""

import unreal
import amandaconda_marco1 as m

# 1) Tira actors Python do nível
m.destroy_unsavable_python_actors()

# 2) Apaga o pacote ExternalActor quebrado (se ainda estiver carregado)
bad = "/Game/__ExternalActors__/ThirdPerson/Lvl_ThirdPerson/A/SI/FZW4Z5S02CP0WYZUDYFGDQ"
try:
    if unreal.EditorAssetLibrary.does_asset_exist(bad):
        unreal.EditorAssetLibrary.delete_asset(bad)
        print("[AMANDACONDA] pacote ExternalActor apagado:", bad)
except Exception as exc:
    print("[AMANDACONDA] delete asset:", exc)

# 3) Recoloca só o que pode salvar + bootstrap transient
m.place_persistent_dummies(save=True)
m.spawn_combat_bootstrap()
print("[AMANDACONDA] OK — agora Ctrl+S (ou ignore se já salvou o resto)")