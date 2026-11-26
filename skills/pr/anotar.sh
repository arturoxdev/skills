#!/usr/bin/env bash
# Dibuja anotaciones numeradas sobre la página abierta en agent-browser.
#   anotar.sh "<selector CSS>" "<nota>" ["<selector>" "<nota>" ...]
#   anotar.sh --limpiar
# Las opciones de agent-browser (p. ej. la sesión) van en AGENT_BROWSER_SESSION.
set -euo pipefail

if [ "${1:-}" = "--limpiar" ]; then
  agent-browser eval "document.querySelectorAll('[data-anotacion-pr]').forEach(n => n.remove()); 'limpio'"
  exit 0
fi

if [ $# -eq 0 ] || [ $(($# % 2)) -ne 0 ]; then
  echo "uso: anotar.sh \"<selector>\" \"<nota>\" [...]  |  anotar.sh --limpiar" >&2
  exit 2
fi

node -e '
const pares = [];
for (let i = 1; i < process.argv.length; i += 2) pares.push([process.argv[i], process.argv[i + 1]]);
console.log(`(${dibuja})(${JSON.stringify(pares)})`);

function dibuja(pares) {
  const ROJO = "#e11d48";
  const faltan = [];
  pares.forEach(([selector, nota], i) => {
    const el = document.querySelector(selector);
    if (!el) return faltan.push(selector);
    el.scrollIntoView({ block: "center", inline: "nearest" });
  });
  if (faltan.length) return "NO ENCONTRADO: " + faltan.join(" , ");
  pares.forEach(([selector, nota], i) => {
    const r = document.querySelector(selector).getBoundingClientRect();
    const caja = document.createElement("div");
    caja.dataset.anotacionPr = "";
    caja.style.cssText = `position:fixed;z-index:2147483647;pointer-events:none;box-sizing:border-box;` +
      `left:${r.left - 4}px;top:${r.top - 4}px;width:${r.width + 8}px;height:${r.height + 8}px;` +
      `border:3px solid ${ROJO};border-radius:6px;`;
    const etiqueta = document.createElement("div");
    etiqueta.dataset.anotacionPr = "";
    etiqueta.textContent = `${i + 1}. ${nota}`;
    const arriba = r.top > 40;
    etiqueta.style.cssText = `position:fixed;z-index:2147483647;pointer-events:none;` +
      `left:${Math.max(4, r.left - 4)}px;${arriba ? `top:${r.top - 34}px` : `top:${r.bottom + 8}px`};` +
      `max-width:420px;padding:4px 8px;border-radius:6px;background:${ROJO};color:#fff;` +
      `font:600 13px/1.4 system-ui,sans-serif;box-shadow:0 2px 6px rgba(0,0,0,.3);`;
    document.body.append(caja, etiqueta);
  });
  return "anotadas: " + pares.length;
}
' "$@" | agent-browser eval --stdin
