---
name: pr
description: Da formato de presentación al cuerpo de un PR — resumen ejecutivo, capturas anotadas, video y tests nuevos.
disable-model-invocation: true
argument-hint: "[número o link del PR]"
---

# PR

Da formato de presentación al PR: $ARGUMENTS

Sin argumento, el PR es el de la rama actual; si la rama no tiene PR, ábrelo contra
la rama de integración (`pruebas` si existe; si no, la rama por defecto del repo) antes de empezar: su número nombra la carpeta de las imágenes. El lector es quien presenta el PR sin haber leído el código: todo el cuerpo
se entiende sin abrir el diff.

## 1. Entender el PR

Lee el diff completo contra la rama base (`gh pr diff`), los commits y el issue que
cierra.

Identifica el issue de GitHub del que viene el PR. Búscalo en el cuerpo actual
(`Closes #n`, «Implementa #n»), en el nombre de la rama (`claude/issue-368`,
`fix/377-…`) y en el título o los commits (`(#317)`). Confirma con `gh issue view <n>`
que es un issue y no otro PR. Un PR puede venir de varios issues, o de ninguno.

Terminado cuando puedes decir, por cada cambio visible para el usuario, qué pasaba antes
y qué pasa ahora, si el PR toca la UI (algo que se ve distinto en pantalla) o no, y de
qué issues viene.

## 2. Tomar las capturas anotadas y el video

Solo cuando el PR toca la UI. Un PR sin cambio en pantalla (API, migraciones, refactor,
dependencias, CI) salta este paso completo: sin capturas y sin video.

Levanta la app en la rama del PR y recorre cada cambio visible con `agent-browser` (lee
su skill antes). Por cada pantalla:

1. Deja la pantalla en el estado que demuestra el cambio.
2. Anota lo que cambió con `anotar.sh "<selector CSS>" "<nota>"`
   (el script vive junto a este `SKILL.md`; acepta varios pares; `--limpiar` quita las anotaciones). La nota dice qué se
   solucionó ahí, no qué es el elemento: «Ya no cuenta las filas excluidas», no «Total».
3. `agent-browser screenshot <n>-<nombre>.png` y mira la imagen: la caja rodea el
   elemento correcto y la nota se lee completa.
4. `--limpiar` antes de pasar a la siguiente pantalla.

Después graba un video con la feature funcionando de principio a fin, sin anotaciones.
Grábalo en **MP4** (`agent-browser record start video.mp4 --fps 15`), nunca en `.webm`:
el MP4 (H.264) es el que se puede ver desde el PR. Saca del mismo flujo un GIF
(`ffmpeg`), que GitHub sí muestra en línea.

Sube capturas, video y GIF a la rama `issue-assets`, carpeta `pr-<número>/`, desde un
worktree temporal para dejar intacto el árbol de trabajo. Se enlazan como
`https://github.com/<owner>/<repo>/blob/issue-assets/pr-<número>/<archivo>?raw=true`
(`<owner>/<repo>` sale de `gh repo view --json nameWithOwner`). Si la rama `issue-assets`
no existe, créala huérfana.

Terminado cuando cada cambio visible del paso 1 tiene una captura anotada, revisada y
subida, y el video y su GIF recorren el flujo completo.

## 3. Listar los tests nuevos

Del diff, saca cada caso de test **agregado** (`test(` / `it(` en líneas nuevas, tanto en
archivos nuevos como en existentes). Los casos modificados o movidos quedan fuera.
Clasifica cada uno por lo que ejercita:

- **E2E**: recorre la UI en un navegador — p. ej. specs de Playwright en `apps/web/e2e/`.
- **Integration**: cruza una frontera real (HTTP, Postgres, varios módulos juntos) —
  p. ej. `apps/api/test/*-http.test.ts` y `*.postgres.test.ts`.
- **Unit**: una función o módulo aislado, sin red ni base —
  p. ej. `apps/api/test/unidad/` y `packages/*/test/`.

La ruta es la pista; lo que decide es lo que el test ejercita.

Terminado cuando cada caso agregado en el diff está en exactamente una categoría.

## 4. Escribir el cuerpo

Reemplaza el cuerpo del PR (`gh pr edit --body-file`) con estas secciones, en este
orden.

Si el PR viene de un issue, la primera línea del cuerpo es `Closes #n`, antes de
**Resumen**: una línea por issue, aunque el cuerpo anterior no la trajera. El formato es
exacto: es la palabra clave que GitHub (y workflows como
`.github/workflows/close-issues-on-pruebas.yml`, si el repo lo tiene) leen para cerrar el
issue al mergear: «Implementa #n» o «Issue #n» no cierran nada. Un issue que
el PR toca pero no termina va como `Refs #n`, que lo deja abierto. Un PR sin issue
empieza directo en **Resumen**.

```markdown
Closes #<n>

## Resumen

<2 a 4 líneas: qué problema había, qué cambió y qué efecto tiene para el usuario.
Lenguaje de negocio; nombres de archivos y funciones se quedan en el diff.>

## Pruebas

### <Pantalla o flujo>
<img src="…/pr-<número>/1-<nombre>.png?raw=true" width="720">

1. <La nota 1 de la captura, ampliada en una línea si hace falta.>
2. <…>

### Video
[Ver video (MP4)](…/pr-<número>/video.mp4?raw=true)

<img src="…/pr-<número>/video.gif?raw=true" width="720">

## ¿Se agregaron tests?

**Sí — <total> nuevos** (o **No.**, y la sección termina ahí)

| Tipo | Nuevos |
| --- | --- |
| E2E | <n> |
| Integration | <n> |
| Unit | <n> |

**E2E**
- `<archivo>` — <nombre del caso>

**Integration**
- …

**Unit**
- …

## Notas

<Lo que hay que saber antes de mergear: migraciones, variables de entorno, pasos
manuales, riesgos, lo que quedó sin verificar.>
```

Las categorías sin tests nuevos llevan 0 en la tabla y se omiten de las listas.
**Notas** va solo cuando hay algo que decir. En un PR que no toca la UI, **Pruebas**
lleva una sola línea: «Sin cambios de UI.»

Terminado cuando el PR en GitHub abre con `Closes #n` por cada issue del paso 1, muestra
cada sección y, si toca la UI, cada imagen y el video cargan
(`gh pr view --web` o revisa las URLs con `curl -I`).
