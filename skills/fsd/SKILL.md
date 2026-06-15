---
name: feature-based-frontend
description: Arquitectura Feature-Based para frontend Next.js (App Router). Úsala SIEMPRE que vayas a crear o ubicar código en un frontend Next.js y necesites decidir DÓNDE va cada archivo: crear un feature, agregar una page.tsx, escribir services (server/client), crear componentes, o estructurar/scaffoldear el repo. La ruta del frontend NO está fija (puede ser src/, apps/web/src/, packages/*/src/, etc.) — la skill detecta la raíz primero. Aplícala aunque el usuario no diga "feature": si vas a tocar la estructura del frontend, consúltala antes para no romper capas, services ni barrels.
---

# Arquitectura Feature-Based — Next.js (App Router)

El frontend se organiza **por dominio de negocio**, no por tipo de archivo. Las dependencias fluyen en una sola dirección: `app/` → `features/` → `shared`. Romper esa dirección genera acoplamiento carísimo de desenredar.

## Paso 0 — Orienta el repo ANTES de crear nada

La raíz del frontend **no es fija**. Antes de ubicar cualquier archivo, detéctala. Llamamos `<SRC>` al directorio que contiene `app/` junto a `features/`, `components/`, `lib/`.

Cómo encontrar `<SRC>`:

1. Localiza el `next.config.*` (`.ts`/`.js`/`.mjs`) — marca la raíz del proyecto Next. En monorepos hay uno por app (ej. `apps/web/`, `apps/admin/`).
2. Dentro de ese proyecto, `<SRC>` es donde vive `app/` (App Router). Suele ser `src/` o la raíz del proyecto. Ejemplos reales: `src/`, `apps/web/src/`, `packages/dashboard/src/`.
3. Si hay **varias** apps Next, elige la que corresponde a la tarea (por el nombre/dominio que pidió el usuario). Si es ambiguo, **pregunta** en cuál trabajar antes de crear archivos.
4. Inspecciona qué carpetas de la estructura ya existen — respeta convenciones presentes (ej. si ya usan `modules/` en vez de `features/`, **no** impongas `features/`; adáptate al nombre que el repo ya use para la capa de dominio).

A partir de aquí, todas las rutas son relativas a `<SRC>`.

## Estructura

```
<SRC>/
├── app/           # SOLO archivos de ruta: page.tsx, layout.tsx, loading.tsx
├── features/      # Módulos por dominio (la mayoría del código vive aquí)
├── components/    # UI compartida (shadcn en ui/, modales globales usados por 3+ features)
├── hooks/         # Hooks genéricos sin lógica de negocio
├── lib/           # Utilidades core (api, config, formatters, utils) + lib/services/ shared
└── types/         # Tipos globales
```

Cada feature por dentro:

```
features/<nombre>/
├── components/                     # UI del feature
├── hooks/                          # Hooks del feature (si aplica)
├── services/
│   ├── <feature>.service.ts        # server-side (apiFetch, next/headers)
│   └── <feature>.client-service.ts # client-side (fetch + API_URL)
├── types/
└── index.ts                        # Barrel / API pública — OBLIGATORIO
```

## Flujo: crear un feature nuevo

Crea un feature cuando hay un **dominio de negocio distinto** con CRUD o workflow propio, o cuando ya tienes 2+ componentes que comparten tipos/lógica. Si dudas, probablemente todavía no lo necesitas.

1. Confirma `<SRC>` (Paso 0) y crea `features/<nombre>/` con las carpetas que vayas a usar (no crees carpetas vacías "por si acaso").
2. Define los tipos del dominio en `types/` (PascalCase: `Contract`, `ClueFormValues`).
3. Escribe los services según necesites server, client o ambos (ver sección siguiente — es lo que más se equivoca).
4. Crea los componentes en `components/` (kebab-case: `contracts-list.tsx`).
5. Escribe el `index.ts` re-exportando **solo lo client-safe**: componentes, client-service y types. Exports **nombrados**, nunca default.
6. Conéctalo desde la page correspondiente en `app/`.

## Reglas de services (la parte no obvia — léela con cuidado)

Por una restricción de **Turbopack**, los services se separan en dos archivos. Mezclarlos rompe el build de formas confusas, así que la separación es funcional, no estética:

- **`<feature>.service.ts`** → funciones **server-side**. Usan `apiFetch()` de `@/lib/api`, que importa `next/headers`. **Solo** las consumen Server Components.
- **`<feature>.client-service.ts`** → funciones **client-side**. Usan `fetch()` con `API_URL` de `@/lib/config`. Para Client Components (`"use client"`).

**El barrel `index.ts` NO re-exporta el `.service.ts` server.** Si lo hace, arrastras `next/headers` al bundle del cliente y truena. Por eso:

```tsx
// Server Component (page.tsx) → importa el service server DIRECTO del archivo
import { getContracts } from "@/features/contratos/services/contratos.service";

// Client Component o cualquier import vía barrel → solo client-safe
import { createDraft, ContractsList } from "@/features/contratos";
```

Reglas que se sostienen siempre:

1. **Ningún componente ni page hace `fetch()` / `apiFetch()` directo.** Todo pasa por un service.
2. Los services **retornan datos tipados** (`Contract[]`, `User`), nunca un `Response` crudo.
3. Un service vive en su feature. Solo se promueve a `lib/services/` cuando lo usan **3+ features** (regla del 3). Con 2, se queda en el dueño y la page compone.

```tsx
// INCORRECTO — page hace fetch directo
const res = await apiFetch("/contracts");
const contracts = res.ok ? await res.json() : [];

// INCORRECTO — client component importa el service server (next/headers!)
import { getContracts } from "@/features/contratos/services/contratos.service";
```

## Reglas de importación entre capas

1. `app/` importa desde features vía `@/features/<nombre>` (puede combinar **varios** features — es la capa de composición).
2. `features/` importan desde shared: `@/components/ui/`, `@/lib/`, `@/hooks/`, `@/lib/services/`.
3. **Un feature NUNCA importa de otro feature.** Si dos lo necesitan, súbelo a shared o compón en la page.
4. **Siempre importa desde el barrel** del feature, nunca deep imports a archivos internos (única excepción: el `.service.ts` server, que va directo por la razón de arriba).

```tsx
// CORRECTO
import { ContractsList, createDraft } from '@/features/contratos';
import { getFlowTypes } from '@/features/flujos';   // OK: estamos en una page de app/
import { getAuthUser } from '@/lib/services/auth';
import { Button } from '@/components/ui/button';

// INCORRECTO — deep import a interno del feature
import { ContractsList } from '@/features/contratos/components/contracts-list';
// INCORRECTO — feature importando de otro feature (dentro de features/contratos/...)
import { FlowEditor } from '@/features/flujos';
```

> Nota: el alias (`@/`) puede variar por repo (`~/`, `@/`, rutas relativas). Verifica el `tsconfig.json`/`paths` en el Paso 0 y usa el alias real del proyecto.

## Reglas de page.tsx (App Router)

Las `page.tsx` son **wrappers delgados de composición**. Su único trabajo es traer datos y ensamblar componentes:

- Hacen data fetching llamando **services** (nunca `apiFetch`/`fetch` directo).
- Pueden combinar services de **varios features**.
- Renderizan componentes de feature.
- **No** contienen lógica de UI compleja ni formularios — eso vive en `features/<nombre>/components/`.

## Dónde poner las cosas (shared vs feature)

| Lo que tienes | Dónde va |
|---|---|
| Componente de design system | `components/ui/` (shadcn) |
| Componente usado por 3+ features | `components/` |
| Componente de un solo dominio | `features/<nombre>/components/` |
| Utilidad sin lógica de negocio | `lib/` |
| Service usado por 3+ features | `lib/services/` |
| Service de un dominio | `features/<nombre>/services/` |
| Hook genérico (ej. use-mobile) | `hooks/` |

**Regla del 3:** algo se promueve a shared cuando lo usan **3+ features**. Con 2, se queda en su dueño.

## Nombrado

- Archivos: **kebab-case** (`contracts-list.tsx`, `contract-draft.ts`).
- Tipos: **PascalCase** (`Contract`, `ClueFormValues`).
- Exports del `index.ts`: **nombrados**, nunca default.

## Checklist antes de dar por terminado

- [ ] ¿Detectaste `<SRC>` y respetaste las convenciones que ya existían en el repo?
- [ ] ¿Cada `fetch`/`apiFetch` está dentro de un service (no en pages ni componentes)?
- [ ] ¿El `.service.ts` server se importa directo y NO se re-exporta en el barrel?
- [ ] ¿Ningún feature importa de otro feature?
- [ ] ¿Todos los imports cross-feature pasan por el `index.ts` (sin deep imports)?
- [ ] ¿La `page.tsx` quedó como wrapper delgado, sin lógica de UI?
- [ ] ¿Los services retornan tipos del dominio, no `Response`?
- [ ] ¿Promoviste a shared solo lo que usan 3+ features?
- [ ] ¿Exports nombrados, kebab-case en archivos, y alias real del repo?
