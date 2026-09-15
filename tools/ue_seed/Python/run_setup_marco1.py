"""Entry point: UnrealEditor-Cmd -ExecutePythonScript=.../run_setup_marco1.py"""

import amandaconda_marco1 as m

m.setup_marco1()
ok = m.verify_marco1()
print("[AMANDACONDA] verify:", ok)
