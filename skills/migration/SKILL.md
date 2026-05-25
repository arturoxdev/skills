name: migrations
description: >-
  Use whenever you modify a Drizzle ORM schema (pgTable/mysqlTable/sqliteTable,
  columns, indexes, relations, enums) and a database migration is needed —
  adding/dropping/renaming columns or tables, changing types, constraints, or
  seeding/backfilling data. Enforces the generate→review→apply workflow, the
  safe handling of destructive changes, and protects migration history. Repo-agnostic.
---

# Drizzle migrations — playbook

You changed (or are about to change) a Drizzle schema. A migration is the
versioned, reviewable record of that change. Do it the safe way: **never let a
schema edit reach a shared database without a reviewed migration.**

## Regla de oro

> El schema `.ts` es la fuente de verdad. Toda diferencia entre el schema y la
> base de datos se materializa en un archivo de migración **versionado,
> revisado y commiteado** — nunca aplicado a ciegas.

---

## Paso 0 — Orientarse (NO asumas la estructura del repo)

Antes de tocar nada, descubre las convenciones del proyecto:

1. **Localiza la config**: busca `drizzle.config.{ts,js,json}`. Lee de ah
   - `dialect` (postgresql / mysql / sqlite / turso / …)
   - `schema` (dónde viven los archivos de schema)
   - `out` (carpeta de migraciones — p. ej. `drizzle/`, `migrations/`)
   - `migrations.table` / `migrations.schema` si están personalizados
2. **Usa los scripts existentes**: revisa `package.json`. Si hay
   `db:generate`, `db:migrate`, `db:push`, `db:check`, **usa esos** en ve
   inventar comandos.
3. **Detecta el package manager** por el lockfile y usa su runner:
   - `bun.lockb`/`bun.lock` → `bunx drizzle-kit …`
   - `pnpm-lock.yaml` → `pnpm dlx drizzle-kit …`
   - `yarn.lock` → `yarn drizzle-kit …`
   - `package-lock.json` → `npx drizzle-kit …`
4. **Mira una migración existente** en la carpeta `out` para imitar el estilo,
   el naming y el dialecto.

> A partir de aquí `<pm>` = el runner que detectaste. Sustitúyelo.

---

## Paso 1 — Decidir: `generate + migrate` vs `push`

| Situación | Comando | Por qué |
|---|---|---|
| Dev, staging, prod, **cualquier DB compartida**, equipo, CI | `generateorial versionado, revisable y reproducible |
| Prototipo local desechable, iteración rápida en tu propia DB | `push` | Sincroniza schema↔DB sin archivos, pero **sin historial** |

**Default = `generate + migrate`.** Usa `push` solo en tu DB local y nunca
contra un entorno que otra persona o un deploy comparta. `push` aplica di
destructivos directamente y sin dejar rastro.

---

## Paso 2 — Editar el schema

Modifica los archivos de schema TypeScript (la ruta que viste en `schema`).
Mantén **un cambio lógico por migración** cuando sea posible — no mezcles
rename con un drop con un add no relacionado.

---

## Paso 3 — Generar la migración

```bash
<pm> drizzle-kit generate --name=<descripcion_corta_en_snake_case>

- El --name produce archivos legibles (0007_add_user_phone.sql) en vez de
nombres aleatorios.
- Esto crea el .sql y actualiza meta/_journal.json + el snapshot. Los
tres son un conjunto atómico: van juntos al commit, nunca por separado.

⚠️ Renames: el prompt interactivo

Si renombraste una columna o tabla, drizzle-kit generate preguntará si es
un rename o un drop + create. Esto importa muchísimo:

- Rename → ALTER … RENAME → conserva los datos. ✅
- drop + create → borra la columna/tabla vieja y crea una nueva vacía →
pérdida de datos. ❌

Corre generate en una terminal que pueda responder el prompt y elige el
rename a conciencia. Si corres en un entorno no interactivo, verifica el SQL
generado con extra cuidado (siguiente paso).

---
Paso 4 — Revisar el SQL generado (OBLIGATORIO)

Abre el .sql recién creado y léelo línea por línea. Drizzle hace un diff, no
adivina tu intención. Busca:

- [ ] DROP TABLE / DROP COLUMN inesperados → pérdida de datos.
- [ ] Un rename que salió como DROP + ADD en vez de RENAME → pérdida de datos.
- [ ] SET NOT NULL / NOT NULL en columna existente sin DEFAULT →
falla si la tabla tiene filas (ver Paso 5).
- [ ] Cambio de tipo sin cláusula de casteo (USING … en Postgres) → puede
fallar o truncar.
- [ ] UNIQUE / PRIMARY KEY nuevo sobre datos con duplicados → falla al ap
- [ ] Que cada sentencia esté separada por el marcador --> statement-breakpoint.

Si el SQL no coincide con tu intención, no lo edites a mano para “arreglarlo”
y luego apliques: corrige el schema .ts, borra la migración recién
generada (aún no aplicada) y regenera. Editar SQL a mano solo es válido para
migraciones custom (Paso 6).

---
Paso 5 — Operaciones destructivas / que preservan datos: patrón expand→contract

Cuando un cambio borraría o perdería datos, divídelo en migraciones
secuenciales (parallel change) en vez de un solo paso destructivo:

Caso: agregar columna NOT NULL a tabla con datos
1. Agrega la columna nullable (o con DEFAULT).
2. Migración custom de backfill que rellena los valores (Paso 6).
3. Migración que pone la columna NOT NULL.

Caso: renombrar/reestructurar conservando datos sin downtime
1. Expand: agrega lo nuevo (columna/tabla) sin quitar lo viejo.
2. Backfill: copia datos viejo → nuevo (migración custom).
3. Migrate code: el código escribe/lee de lo nuevo.
4. Contract: en una migración posterior, elimina lo viejo.

Caso: cambio de tipo que no castea automáticamente
- Columna nueva con el tipo destino → backfill con conversión → swap → dr

La regla: expandir y respaldar antes de contraer. Nunca un DROP
destructivo en el mismo paso que crea el reemplazo.

---
Paso 6 — Migraciones de datos / seed / DDL no soportado

Para backfills, seeds o SQL que Drizzle no genera:

<pm> drizzle-kit generate --custom --name=backfill_<algo>

Genera un .sql vacío. Escribe tu SQL a mano (UPDATE/INSERT/DML). Se aplic
el mismo migrate y queda versionado junto a las migraciones de schema. Mantén
las migraciones de datos separadas de las de DDL.

---
Paso 7 — Aplicar

<pm> drizzle-kit migrate

- Aplica las migraciones pendientes y las registra en la tabla de journal
(__drizzle_migrations por defecto, o la de migrations.table).
- Nunca uses push contra una DB compartida para aplicar estos cambios.
- En producción, aplica vía el migrator en runtime/CI, p. ej.:
import { migrate } from "drizzle-orm/<driver>/migrator";
await migrate(db, { migrationsFolder: "<out>" });

---
Paso 8 — Commit y verificación

1. Commitea juntos: el schema .ts + el/los .sql + meta/_journal.json
  - los snapshots. Son un solo cambio atómico.
2. En CI / equipo corre:
<pm> drizzle-kit check
2. Detecta colisiones (dos ramas que generaron la misma migración N).
3. Verifica: corre la suite de tests / la app contra una DB con la migrac
aplicada e inspecciona el resultado.

---
NUNCA hagas esto

- ❌ Editar o borrar una migración ya aplicada a una DB compartida. En su
lugar genera una nueva migración hacia adelante que corrija.
- ❌ Editar a mano meta/_journal.json o los snapshots *.json. Si hay
conflicto de merge tras un rebase, regenera, no lo resuelvas a mano.
- ❌ Commitear un cambio de schema sin su migración (o viceversa).
- ❌ push contra staging/prod o cualquier DB que no sea tuya y desechable.
- ❌ Aceptar a ciegas un rename como drop + create.
- ❌ Aplicar un .sql sin haberlo leído.

Resolución de conflictos de journal (tras merge/rebase)

Si dos ramas crearon migraciones, el _journal.json choca. No edites el JSON:
reordena tomando tu schema actual como verdad, borra tus migraciones loca
no aplicadas, sincroniza con la rama base y vuelve a generate. Confirma con
drizzle-kit check.
