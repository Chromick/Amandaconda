# Recria o projeto Unreal em pasta REAL no D: (sem junction/OneDrive).
# Uso: powershell -ExecutionPolicy Bypass -File tools\recriar_projeto_unreal_d.ps1

$ErrorActionPreference = "Stop"

$OldOneDrive = "C:\Users\bruno\OneDrive\Documentos\Unreal Projects\Amandaconda"
$Junction    = "D:\AmandacondaUE"
$Staging     = "D:\AmandacondaUE_BUILD"
$Seed        = Join-Path $PSScriptRoot "ue_seed"
$Uproject    = Join-Path $Staging "Amandaconda.uproject"
$Ddc         = "D:\UE_DDC"

Write-Host "==> Fechando Unreal (se aberto)..."
Get-Process | Where-Object { $_.ProcessName -match 'UnrealEditor|UnrealEditor-Cmd|CrashReportClient' } |
  Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

if (-not (Test-Path $OldOneDrive)) {
  if (Test-Path $Junction) {
    $item = Get-Item $Junction -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      throw "OneDrive antigo sumiu mas junction ainda existe. Pare e verifique."
    }
  }
}

if (Test-Path $Staging) {
  Write-Host "==> Limpando staging $Staging"
  Remove-Item $Staging -Recurse -Force
}
New-Item -ItemType Directory -Path $Staging | Out-Null

$Source = $OldOneDrive
if (-not (Test-Path $Source)) { $Source = $Junction }
if (-not (Test-Path $Source)) { throw "Nenhuma fonte de projeto encontrada." }

Write-Host "==> Copiando Content/Config de:"
Write-Host "    $Source"
& robocopy $Source $Staging /E /NFL /NDL /NJH /NJS /nc /ns /np `
  /XD Intermediate DerivedDataCache Binaries .vs Saved `
  /XF *.log *.dmp
if ($LASTEXITCODE -ge 8) { throw "robocopy falhou code=$LASTEXITCODE" }

New-Item -ItemType Directory -Force -Path (Join-Path $Staging "Saved") | Out-Null
Copy-Item (Join-Path $Seed "COMO_ABRIR.txt") (Join-Path $Staging "Saved\COMO_JOGAR_MARCO2.txt") -Force

Write-Host "==> Aplicando seed (ini leve + Python Marco 2)..."
New-Item -ItemType Directory -Force -Path (Join-Path $Staging "Content\Python") | Out-Null
Copy-Item (Join-Path $Seed "Python\*") (Join-Path $Staging "Content\Python\") -Force
Copy-Item (Join-Path $Seed "DefaultEngine.ini") (Join-Path $Staging "Config\DefaultEngine.ini") -Force
Copy-Item (Join-Path $Seed "Amandaconda.uproject") $Uproject -Force

New-Item -ItemType Directory -Force -Path $Ddc | Out-Null
$ddcLine = @"

; DDC em disco D: (fora do OneDrive)
[InstalledDerivedDataBackendGraph]
Local=(Type=FileSystem,ReadOnly=false,Clean=false,Flush=false,PurgeTransient=true,DeleteUnused=true,UnusedFileAge=34,FoldersToClean=-1,Path="D:/UE_DDC",EnvPathOverride=UE-LocalDataCachePath,EditorOverrideSetting=UE-LocalDataCachePath)
"@
Add-Content -Path (Join-Path $Staging "Config\DefaultEngine.ini") -Value $ddcLine

Write-Host "==> Removendo junction / pasta antiga em D:\AmandacondaUE..."
if (Test-Path $Junction) {
  $item = Get-Item $Junction -Force
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    cmd /c "rmdir `"$Junction`""
  } else {
    Remove-Item $Junction -Recurse -Force
  }
}

Write-Host "==> Movendo staging -> D:\AmandacondaUE (pasta REAL)..."
Rename-Item $Staging $Junction

Write-Host "==> Apagando projeto no OneDrive (libera C:)..."
if (Test-Path $OldOneDrive) {
  Remove-Item $OldOneDrive -Recurse -Force
}

$attr = (Get-Item $Junction -Force).Attributes
if ($attr -band [IO.FileAttributes]::ReparsePoint) {
  throw "Ainda e junction - algo deu errado."
}

Write-Host ""
Write-Host "OK - projeto fresco em pasta REAL:"
Write-Host "  $Junction\Amandaconda.uproject"
Write-Host "Abra por esse caminho. Nao use OneDrive."
Write-Host "DDC: $Ddc"
