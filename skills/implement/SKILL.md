---
name: implement
description: Implementa un issue o feature de punta a punta, la verifica y manda el PR a la rama de integración (`pruebas`).
argument-hint: "[link del issue]"
---

# Implement

Protocolo para implementar un issue o feature: $ARGUMENTS

## 1. Reunir el ticket

- Con link: lee el issue completo desde su fuente (cuerpo y comentarios). Para GitHub,
  `gh issue view <n> --comments` (y `docs/agents/issue-tracker.md` si el repo lo tiene).
- Sin link: el ticket es lo que está en el chat.

Terminado cuando puedes listar cada criterio de aceptación del ticket.

## 2. Planear

Planea la implementación antes de tocar código: qué módulos cambian y cómo vas a
verificar cada criterio.

Terminado cuando cada criterio tiene asignados un cambio y una verificación.

## 3. Implementar y verificar

Trabaja en una rama nueva creada desde la rama de integración: `pruebas` si existe; si
no, la rama por defecto del repo. Esa misma es la base del PR. Verifica cada feature con la
herramienta que le toca:

- UI: `agent-browser` (lee su skill antes) o Chrome DevTools.
- API: peticiones `curl`.

Los tests E2E van solo cuando el ticket los pida, y solo los que pida. Antes de
escribirlos, lee `docs/TEST-PATTERNS.md` si existe.

Terminado cuando cada criterio del ticket está verificado en ejecución real, cada test
E2E que pidió el ticket pasa y los quality gates del repo (`AGENTS.md`/`CLAUDE.md`: lint, typecheck, tests) están en verde.

## 4. Mandar el PR

Abre el PR de tu rama a la rama de integración y dale formato siguiendo la skill `pr`
completa (`../pr/SKILL.md`): ahí viven las secciones del cuerpo (resumen,
capturas anotadas y video solo si el PR toca la UI, tests nuevos, notas) y cómo producir cada una.

Terminado cuando el PR está abierto contra la rama de integración y cumple el criterio final de ese
documento.
