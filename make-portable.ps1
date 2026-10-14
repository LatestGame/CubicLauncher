$ErrorActionPreference = 'Stop'
$ver  = '33.2.0'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$out  = Join-Path $root 'dist-portable\ShiftLauncher'
$tmp  = Join-Path $env:TEMP "cubic-electron-$ver"
$name = "electron-v$ver-win32-x64.zip"
$base = "https://github.com/electron/electron/releases/download/v$ver"
$zip  = Join-Path $tmp $name
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=== Сборка портативного Shift Launcher (Electron $ver) ==="
New-Item -ItemType Directory -Force $tmp | Out-Null

if (-not (Test-Path $zip)) {
    Write-Host 'Скачиваю Electron с GitHub (около 110 МБ)...'
    Invoke-WebRequest "$base/$name" -OutFile $zip
}

Write-Host 'Проверяю контрольную сумму...'
$sums = (Invoke-WebRequest "$base/SHASUMS256.txt").Content
if ($sums -is [byte[]]) { $sums = [Text.Encoding]::UTF8.GetString($sums) }
$line = ($sums -split "`n") | Where-Object { $_ -match [regex]::Escape($name) } | Select-Object -First 1
if (-not $line) { throw 'Не нашёл контрольную сумму Electron на GitHub.' }
$expected = ($line.Trim() -split '\s+')[0].ToLower()
$actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($expected -ne $actual) {
    Remove-Item $zip -Force
    throw 'Контрольная сумма не совпала — файл удалён. Запустите скрипт ещё раз.'
}

if (Test-Path $out) { Remove-Item $out -Recurse -Force }
Write-Host 'Распаковываю...'
Expand-Archive $zip -DestinationPath $out

$app = Join-Path $out 'resources\app'
New-Item -ItemType Directory -Force $app | Out-Null
Copy-Item (Join-Path $root 'src') (Join-Path $app 'src') -Recurse

# package.json без devDependencies; пишем UTF-8 БЕЗ BOM (с BOM Electron не прочитает файл)
$pkg = Get-Content (Join-Path $root 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$min = [ordered]@{ name = $pkg.name; productName = $pkg.productName; version = $pkg.version; description = $pkg.description; main = $pkg.main; private = $true }
[IO.File]::WriteAllText((Join-Path $app 'package.json'), ($min | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))

Remove-Item (Join-Path $out 'resources\default_app.asar') -Force -ErrorAction SilentlyContinue
Rename-Item (Join-Path $out 'electron.exe') 'ShiftLauncher.exe'

$readme = @"
Shift Launcher - портативная версия для Windows 10/11 (x64).
Запустите ShiftLauncher.exe. Данные (сборки, моды, миры) хранятся в %APPDATA%\ShiftLauncher,
поэтому папку с программой можно переносить и удалять без потери сборок.
Windows может показать предупреждение SmartScreen: файл не подписан. Нажмите "Подробнее" - "Всё равно запустить".
"@
Set-Content (Join-Path $out 'README.txt') $readme -Encoding UTF8

Write-Host ''
Write-Host "Готово: $out\ShiftLauncher.exe"
Start-Process explorer.exe $out
