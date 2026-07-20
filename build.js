#!/usr/bin/env node
// build.js — Gera index.html a partir de _template.html + products.json + slides.json
// + imagens WebP + fontes + SVG do logo.
// Roda tanto localmente (node build.js) quanto no GitHub Actions.
// Reexecute sempre que editar o template, o products.json, o slides.json ou trocar imagens.

const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const log = (msg) => console.log(msg);

log('Lendo template...');
let out = fs.readFileSync(path.join(ROOT, '_template.html'), 'utf8');

// split/join = substituição literal, sem interpretar $&, $1 etc. como regex faria
function replaceAll(str, token, value) {
  return str.split(token).join(String(value));
}

log('Injetando dados dos produtos (products.json)...');
const produtos = JSON.parse(fs.readFileSync(path.join(ROOT, 'products.json'), 'utf8'));
const produtosJs = JSON.stringify(produtos).replace(/<\//g, '<\\/');
out = replaceAll(out, '__PRODUTOS_JSON__', produtosJs);

log('Injetando títulos e labels dos hotspots (slides.json)...');
const slides = JSON.parse(fs.readFileSync(path.join(ROOT, 'slides.json'), 'utf8'));
for (const [num, texto] of Object.entries(slides.titles || {})) {
  out = replaceAll(out, `__TITLE_${num}__`, texto);
}
for (const [id, texto] of Object.entries(slides.pills || {})) {
  out = replaceAll(out, `__PILL_${id}__`, texto);
}

log('Convertendo WebPs para base64...');
const WEBP_MAP = {
  CAPA: 'CAPA.webp',
  P1: 'Sacolas Papel Cartão.webp',
  P2: 'Sacolas Kraft.webp',
  P3: 'Sacola Boca Vazada.webp',
  P4: 'Sacola Alça Fita.webp',
  P5: 'Sacola Alça Cordão.webp',
  P6: 'Sacola Alça Camiseta.webp',
  P7: 'Papel Seda.webp',
  P8: 'Fita de Cetim.webp',
  P9: 'Etiquetas e Tags.webp',
  P10: 'Caixas Simples.webp',
  P11: 'E-Commerce.webp',
  P12: 'Seda e Etiqueta.webp',
  P13: 'Bobinas de Papel de Presente.webp',
  CTA: 'CTA.webp',
};
for (const [key, filename] of Object.entries(WEBP_MAP)) {
  const b64 = fs.readFileSync(path.join(ROOT, 'webp', filename)).toString('base64');
  out = replaceAll(out, `__${key}_B64__`, b64);
}

log('Convertendo fontes para base64...');
const FONT_MAP = {
  FONT_LIGHT: 'NiveauGrotesk-Light.otf',
  FONT_REGULAR: 'NiveauGrotesk-Regular.otf',
  FONT_BLACK: 'NiveauGrotesk-Black.otf',
};
for (const [key, filename] of Object.entries(FONT_MAP)) {
  const b64 = fs.readFileSync(path.join(ROOT, 'fonts', filename)).toString('base64');
  out = replaceAll(out, `__${key}_B64__`, b64);
}

// Logo SVG (opcional — só substitui se o arquivo existir e o placeholder ainda estiver no template)
const logoPath = path.join(ROOT, 'LOGO HORIZONTAL - B.svg');
if (out.includes('__LOGO_SVG__') && fs.existsSync(logoPath)) {
  log('Preparando SVG do logo...');
  let logoRaw = fs.readFileSync(logoPath, 'utf8');
  logoRaw = logoRaw.replace(/<\?xml[^>]*\?>\s*/, '');
  logoRaw = logoRaw.replace(/<defs>[\s\S]*?<\/defs>\s*/, '');
  logoRaw = logoRaw.trim();
  const logoWhite = logoRaw.replace(/^<svg /, '<svg fill="#ffffff" ');
  out = replaceAll(out, '__LOGO_SVG__', logoWhite);
}

log('Verificando integridade...');
const pendentes = out.match(/__[A-Z0-9_]+__/g);
if (pendentes) {
  console.error('ERRO: placeholders nao substituidos:', [...new Set(pendentes)].join(', '));
  process.exit(1);
}

log('Gravando index.html (UTF-8 sem BOM)...');
fs.writeFileSync(path.join(ROOT, 'index.html'), out, 'utf8');

const size = fs.statSync(path.join(ROOT, 'index.html')).size;
log(`OK: index.html gerado (${size.toLocaleString('pt-BR')} bytes / ${(size / 1024).toFixed(1)} KB)`);
