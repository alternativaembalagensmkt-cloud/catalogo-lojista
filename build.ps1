# build.ps1 — Gera index.html a partir de _template.html + imagens WebP + SVG do logo.
# Reexecute sempre que editar o template ou adicionar imagens.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Lendo template..." -ForegroundColor Cyan
$tmpl = [IO.File]::ReadAllText("$PSScriptRoot\_template.html")

Write-Host "Convertendo WebPs para base64..." -ForegroundColor Cyan
$capa = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\CAPA.webp"))
$p1   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacolas Papel Cartão.webp"))
$p2   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacolas Kraft.webp"))
$p3   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacola Boca Vazada.webp"))
$p4   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacola Alça Fita.webp"))
$p5   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacola Alça Cordão.webp"))
$p6   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Sacola Alça Camiseta.webp"))
$p7   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Papel Seda.webp"))
$p8   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Fita de Cetim.webp"))
$p9   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Etiquetas e Tags.webp"))
$p10  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Caixas Simples.webp"))
$p11  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\E-Commerce.webp"))
$p12  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Seda e Etiqueta.webp"))
$p13  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\Bobinas de Papel de Presente.webp"))
$cta  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\webp\CTA.webp"))

Write-Host "Convertendo fontes para base64..." -ForegroundColor Cyan
$fontLight   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\fonts\NiveauGrotesk-Light.otf"))
$fontRegular = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\fonts\NiveauGrotesk-Regular.otf"))
$fontBlack   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\fonts\NiveauGrotesk-Black.otf"))

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
$out = $out.Replace('__P10_B64__',  $p10)
$out = $out.Replace('__P11_B64__',  $p11)
$out = $out.Replace('__P12_B64__',  $p12)
$out = $out.Replace('__P13_B64__',  $p13)
$out = $out.Replace('__CTA_B64__',  $cta)
$out = $out.Replace('__LOGO_SVG__', $logoWhite)
$out = $out.Replace('__FONT_LIGHT_B64__',   $fontLight)
$out = $out.Replace('__FONT_REGULAR_B64__', $fontRegular)
$out = $out.Replace('__FONT_BLACK_B64__',   $fontBlack)

Write-Host "Verificando integridade..." -ForegroundColor Cyan
$placeholders = @('__CAPA_B64__','__P1_B64__','__P2_B64__','__P3_B64__','__P4_B64__',
                  '__P5_B64__','__P6_B64__','__P7_B64__','__P8_B64__','__P9_B64__',
                  '__P10_B64__','__P11_B64__','__P12_B64__','__P13_B64__','__CTA_B64__','__LOGO_SVG__',
                  '__FONT_LIGHT_B64__','__FONT_REGULAR_B64__','__FONT_BLACK_B64__')
$pending = $placeholders | Where-Object { $out.Contains($_) }
if ($pending) {
    Write-Host ("ERRO: placeholders nao substituidos: " + ($pending -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Host "Gravando index.html (UTF-8 sem BOM)..." -ForegroundColor Cyan
[IO.File]::WriteAllText("$PSScriptRoot\index.html", $out, [System.Text.UTF8Encoding]::new($false))

$size = (Get-Item "$PSScriptRoot\index.html").Length
Write-Host ("OK: index.html gerado ({0:N0} bytes / {1:N1} KB)" -f $size, ($size/1KB)) -ForegroundColor Green
