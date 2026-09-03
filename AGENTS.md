# AGENTS.md — Dockspace

Guia de convenções pra qualquer agente (Mavis, Codex, Cursor, Devin) ou humano que mexa neste repo. Lido antes de qualquer task de código.

## Visão rápida

App macOS nativo (Swift + SwiftUI, macOS 14+) de menu bar que troca o conjunto de apps pinned no Dock entre perfis nomeados. 100% local, open source MIT.

Inspirado pelo [Dockset](https://dockset.app/) (pago). Referência técnica mais próxima: [DockManager](https://github.com/graddotdev/DockManager) (Swift, MIT, 2020, sem updates — vale ler o source pra inspiração mas não copiar).

## Stack e constraints

- **Linguagem:** Swift 5.9+. Usar SwiftUI sempre que possível, AppKit só quando não der (hotkey global, NSDockTile se necessário).
- **Platform:** macOS 14 Sonoma floor. Não tentar backport pra 13/12 — SwiftUI moderno (`MenuBarExtra`, `@Observable`, `.inspector`) só funciona bem de 14+.
- **No dependências externas de runtime.** Manter zero SPM deps no MVP. Se precisar, justificar no PR.
- **Sem cloud, sem rede, sem analytics, sem crash reporting remoto.** Open source exige confiança.
- **LGPL/GPL não permitido** em deps (combate com MIT). MIT/Apache 2.0/BSD ok.

## Layout

```
Sources/
├── DockspaceApp/        # UI (SwiftUI)
├── DockspaceCore/       # lógica pura (plist, swapper, models)
└── DockspaceStorage/    # persistência (JSON, backup)

Tests/
└── DockspaceCoreTests/  # testes do Core (lógica testável, rápida)

Scripts/
└── build-app.sh         # gera .app bundle a partir de swift build
```

**Regra:** `DockspaceCore` não importa `DockspaceApp` ou `DockspaceStorage`. `DockspaceStorage` depende de `DockspaceCore` (pelos models), mas não da UI. UI depende de tudo.

## Convenções de código

- **Swift style:** seguir SwiftLint padrão (será adicionado no CI na Fase 1). Máximo 120 chars/linha.
- **Naming:** `Dockspace` prefix em todos os tipos públicos (`DockProfile`, não `Profile`).
- **File naming:** um tipo principal por arquivo, mesmo nome do tipo (`DockProfile.swift`).
- **Concurrency:** `actor` pra qualquer estado mutável compartilhado. `@MainActor` em tudo que toca UI.
- **State global:** `AppState` como `@Observable`, injetado via `.environment`.
- **Errors:** `enum DockError: LocalizedError` no Core. Throw, não force-unwrap. Mensagens começam com verbo ("Failed to read plist because ...").
- **Logging:** `os.Logger` com subsystem `app.dockspace`. Categorias: `.pl`, `.storage`, `.ui`, `.hotkey`.
- **Testes:** XCTest, não Swift Testing (mais maduro, mais docs). Todo código de Core com teste.

## Commits

- **Conventional Commits** com scope obrigatório: `feat(core): add DockPlistReader`, `fix(ui): crash on empty profile`, `chore(repo): bootstrap project`, `docs(readme): clarify build steps`.
- **Escopo = target primário** (`core`, `storage`, `ui`, `app`, `repo`, `docs`, `ci`).
- **Mensagem em inglês, imperativo, sem ponto final.** Body opcional explicando o "porquê", não o "quê".
- **Commits granulares.** Um commit por mudança lógica. Se o PR toca UI e Core, são pelo menos 2 commits.
- **Identidade:** commitar como o Luciano (`Luciano dii Souza <lucianodiisouza@hotmail.com>`), nunca como agente. Se agente for commitar, setar `git -c user.name=... -c user.email=... commit ...` explicitamente.

## Branches

- `main` = sempre compilável, sempre passa em CI. Releases saem daqui.
- `feat/<slug>` = feature em progresso. Rebase, não merge.
- `fix/<slug>` = bug fix.
- Sem `dev`/`staging`. PR direto pra `main` depois de passar no CI.

## Roadmap (resumo)

| Fase | Entrega | Status |
|---|---|---|
| 0 | Bootstrap (Package.swift, CI, README) | ✅ |
| 1 | `DockPlistReader` + `DockPlistWriter` + testes | ✅ |
| 2 | `ProfileStore` (JSON CRUD) + `BackupManager` | ✅ |
| 3 | MVP UI: MenuBarExtra + ProfileEditor + switch | ✅ |
| 4 | Hotkeys globais + Focus Mode + Settings + Change detection | ✅ |
| 5 | Polish: ícone, onboarding, i18n | Pendente |
| 6 | Release v0.2: DMG assinado, site, GitHub Release | Pendente |

Plano completo vive em conversa e nas issues. Não foi materializado em `docs/PLAN.md` por enquanto.

## Riscos conhecidos

- **`killall Dock` causa un-minimize** de janelas minimizadas. Inevitável. Documentar.
- **cfprefsd caching:** escrever no plist sem notificar o daemon = mudança invisível. Usar `DistributedNotificationCenter` + `killall cfprefsd Dock` no swap.
- **Apps em `persistent-others`** (folders, files, URLs) também precisam ser salvos/swappados — não só `persistent-apps`.
- **Editing manual do Dock entre switches:** usuário pode mexer; Dockspace precisa detectar (diff entre snapshot e estado atual) e perguntar merge/overwrite.

## Comandos úteis

```bash
# Dev rápido
swift run Dockspace

# Testes
swift test

# Build .app bundle
./Scripts/build-app.sh

# Limpar build
swift package clean
```

## Pra agentes voltando nesse repo

1. Ler esse arquivo inteiro antes de codar.
2. Olhar issues abertas antes de propor mudanças grandes.
3. Se for adicionar dep nova, justificar no PR e atualizar esse arquivo.
4. Não commitar com identidade do agente — sempre setar `user.name`/`user.email` do Luciano.
5. Antes de PR, rodar `swift test` + verificar `swift build` limpo.
