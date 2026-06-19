# Demo and Storybook

AshSDUI treats the demo app and Storybook as proof surfaces for the public
package contract.

## Why they exist

The package has several overlapping authoring paths: generated screens, custom
recipes, ephemeral layouts, persisted layouts, and runtime-aware components.
Without a proof surface, it would be easy for those paths to drift apart while
still appearing coherent in isolated module docs.

The demo app and Storybook keep that drift visible. They show whether promoted
features still compose into a believable UI runtime instead of only passing unit
tests.

## What each surface proves

`examples/sdui_demo` is the integration surface. It maps a promoted feature to a
canonical route, often a Storybook leaf, and at least one regression test. That
coverage matrix is the package's public proof ledger for generated screens,
query lifecycle, live bindings, workflow state, hybrid layouts, and persisted
layouts.

Storybook is the visual isolation surface. In AshSDUI it is most valuable when
it renders generated views and reusable runtime-aware building blocks through
the same `SDUIRoot` path used elsewhere. That is why higher-level stories are
preferred over stories that only showcase the lowest-level raw components.

## Why this matters to the public API

The package positions `AshSDUI.LiveResource`, `AshSDUI.Layout`, and the shared
runtime contract as stable user-facing abstractions. The demo app and Storybook
help verify that those abstractions remain consistent in practice, not only in
type signatures and doc prose.

They also make feature promotion stricter. A capability is more trustworthy when
it has a route, a story when visual isolation helps, and a regression test that
exercises the same behavior.

## Where to look

See `examples/sdui_demo/README.md` for the current coverage matrix and public
feature map. Use Storybook stories as supporting proof of generated views and
runtime-aware building blocks, not as the primary conceptual entrypoint to the
package.
