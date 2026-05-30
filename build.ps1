# build.ps1 — Gera index.html a partir de _template.html + imagens WebP + SVG do logo.
# Reexecute sempre que editar o template ou adicionar imagens.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Lendo template..." -ForegroundColor Cyan
$tmpl = [IO.File]::ReadAllText("$PSScriptRoot\_template.html")

Write-Host "Convertendo WebPs para base64..." -ForegroundColor Cyan
$capa = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\CAPA.webp"))
$p1   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P1.webp"))
$p2   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P2.webp"))
$p3   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P3.webp"))
$p4   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P4.webp"))
$p5   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P5.webp"))
$p6   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P6.webp"))
$p7   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P7.webp"))
$p8   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\P8.webp"))
$p9File = Get-ChildItem "$PSScriptRoot\webp\P9*.webp" | Select-Object -First 1
$p9   = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p9File.FullName))

Write-Host "Preparando SVG do logo (remove <style> interno para evitar colisao de classes)..." -ForegroundColor Cyan
$logoRaw = [IO.File]::ReadAllText("$PSScriptRoot\LOGO HORIZONTAL - B.svg")
# tira declaracao XML
$logoRaw = [regex]::Replace($logoRaw, '<\?xml[^>]*\?>\s*', '')
# tira bloco <defs>...</defs> (que contem o <style> com .cls-1) — usa (?s) pra DOTALL
$logoRaw = [regex]::Replace($logoRaw, '(?s)<defs>.*?</defs>\s*', '')
$logoRaw = $logoRaw.Trim()

# Insere atributo fill no <svg> raiz. Paths sem fill explicito herdam do parent.
$logoWhite = [regex]::Replace($logoRaw, '^<svg ', '<svg fill="#ffffff" ')

Write-Host "Substituindo placeholders..." -ForegroundColor Cyan
$out = $tmpl
$out = $out.Replace('__CAPA_B64__', $capa)
$out = $out.Replace('__P1_B64__',   $p1)
$out = $out.Replace('__P2_B64__',   $p2)
$out = $out.Replace('__P3_B64__',   $p3)
$out = $out.Replace('__P4_B64__',   $p4)
$out = $out.Replace('__P5_B64__',   $p5)
$out = $out.Replace('__P6_B64__',   $p6)
$out = $out.Replace('__P7_B64__',   $p7)
$out = $out.Replace('__P8_B64__',   $p8)
$out = $out.Replace('__P9_B64__',   $p9)
$out = $out.Replace('__LOGO_SVG__', $logoWhite)

Write-Host "Verificando integridade..." -ForegroundColor Cyan
$placeholders = @('__CAPA_B64__','__P1_B64__','__P2_B64__','__P3_B64__','__P4_B64__',
                  '__P5_B64__','__P6_B64__','__P7_B64__','__P8_B64__','__P9_B64__','__LOGO_SVG__')
$pending = $placeholders | Where-Object { $out.Contains($_) }
if ($pending) {
    Write-Host ("ERRO: placeholders nao substituidos: " + ($pending -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Host "Gravando index.html (UTF-8 sem BOM)..." -ForegroundColor Cyan
[IO.File]::WriteAllText("$PSScriptRoot\index.html", $out, [System.Text.UTF8Encoding]::new($false))

$size = (Get-Item "$PSScriptRoot\index.html").Length
Write-Host ("OK: index.html gerado ({0:N0} bytes / {1:N1} KB)" -f $size, ($size/1KB)) -ForegroundColor Green
