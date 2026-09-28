# Changelog

This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta.8] - 2026-09-28

### Added

- Each release attaches the eight honk-core builds of honk's `debug` pre-release, so honk does not have to be compiled: x86_64 and aarch64, glibc and musl, each with mimalloc or the system allocator. `honk-source-<commit>.tar.gz` holds the source of the honk commit they were built from and `HONK-SOURCE.txt` names that commit; `SHA256SUMS` lists every release asset except itself. The builds are attached until honk publishes a release with the native API. (#109, #117)
- Sign-in is a full page instead of a dialog over an empty window, with its own language menu and theme toggle. From 1024 pixels wide, a panel beside the form shows a construction scene that becomes a small Flappy Duck game when pressed. The form keeps working if the scene fails to load, and the scene is a still picture when reduced motion is requested. (#107, #114, #115)
- The public demo opens on the sign-in page with its account filled in: user name `demo`, password `demo`. (#107)
- The setup guide is a separate documentation site in English, Simplified Chinese and Traditional Chinese, maintained in [Zakkaus/doona-docs](https://github.com/Zakkaus/doona-docs). Sign-in and Settings > About link to it; the sign-in hint for a backend without the native API and the read-only outbound mode help open its troubleshooting sections. (#100)
- The documentation site has step-by-step installation pages for Debian or Ubuntu, Fedora or RHEL, Arch Linux, Gentoo, OpenWrt and other systems, and follows the layout of the React Spectrum docs. Its search ranks titles first and works from the keyboard, the 404 page is in the reader's language, and Chinese pages use the Spectrum CJK type scale. Colours are correct in Safari 17.0 to 17.4, and links into doona's source work when the pages are read on GitHub. The pages are shared under CC BY 4.0, and the header links to the demo. (Zakkaus/doona-docs#1, #2, #3, #6, #11, #13, #14)
- Help buttons explain unclear states and terms on Overview, Connections, Configuration, Rules, Policies, DNS, Events, Logs and Settings. (#98)
- Overview lists the features that are off in a full-width card, one row per cause. Where one applies, a row explains the cause, gives the configuration lines that turn the feature on, or links to the documentation or Settings. The rule list, validation and closing connections are listed when the backend lacks them. The count on Activity links to the card. (#102)
- A disabled action says why in a line beside its buttons, visible at every width, where before the reason was only in a tooltip that touch does not open, or missing. This covers Configuration, Activity, Policies, Rules, DNS, Nodes and Settings, and the dialogs for new rules, subscriptions and nodes. Screen readers read the line as the button's description. (#97, #127, #130, #133)
- Connections can collapse and expand each group, or all groups at once, while the list is grouped. (#93)
- On Events and Logs, pressing a row, or Enter or Space on it, shows its full text below the table, so text cut on a phone can be read; pressing the row again hides it. (#105)
- The demo shows its error states when opened with `?scenario=faults`; `?scenario=` returns to the healthy demo. (#103)

### Changed

- The demo behaves as a healthy honk: it seeds no failures, and switching the outbound mode works. (#103)
- The Overview header and the Activity status add a degraded or failed datapath to the engine state, in the matching tone. The Overview header links to the Datapath card. (#102)
- Backend features on Overview lists only the features that are on. (#102)
- Configuration shows each source's path once. A read-only source has one badge naming the reason (generated, subscription, read-only, contains secrets, redacted or text not returned) and no Validate button; when configuration writes are off, help beside the badge says how to turn them on. Every source with text has one line saying what it is and what can be done with it, and all source editors start at the same height. (#101)
- A writable source is edited in place, without an Edit button. Typing, pasting or tapping in a read-only source shows one notice with the reason. (#101)
- When a save finds that the file changed on disk, the source card, the modules and the quick setup show an alert and wait until the draft is kept over the change or discarded; previously, the draft was applied to the changed file without warning. A module draft carries over on its own when the change is outside its section. (#118)
- Read-only code editors show no caret or current-line highlight; the line a source was opened at keeps a marker. (#97)
- The must switch in the new-rule dialog reads Lock this outbound, with a line explaining what a locked outbound skips. (#91)
- The outbound mode card and the Arrange review label their button Apply and reload, as Configuration does, since all three write the configuration and reload it. (#126)
- Below 600 pixels wide, tables keep every column at its minimum width and scroll sideways, instead of dropping columns until the rest fit. Wider screens drop columns as before. (#128)
- On Policies, a large node group lays out its tiles like a small group: the same columns, tile width and edges, with room left for the scrollbar. (#125)
- The busiest-host tile on Connections takes two shares of its row. A host that still does not fit keeps its end visible and shows the full name on hover, focus or tap. (#99)
- When a subscription refresh leaves the datapath degraded, the notice says that new connections proxied through userspace are refused and points to Overview. (#98)
- The Chinese token sign-in heading and missing-token message use formal wording. (#107)
- README screenshots are rendered by the documentation site on each deploy and are no longer stored in the repository. (Zakkaus/doona-docs#6)
- NOTICE, `REUSE.toml`, the READMEs and the `OFL.txt` shipped with the fonts name Adobe as the copyright holder of Noto Sans TC and SC. The documentation site credits Adobe for the Spectrum icons, fonts and design. (#122, Zakkaus/doona-docs#12)

### Fixed

- Errors with the reused codes `invalid_request`, `unsupported_value` and `state_conflict` keep the backend's own message beside the summary. (#94)
- A backend that never answers no longer leaves a page loading. API reads fail when the headers, or the next part of the body, take more than 15 seconds to arrive, and writes when they take more than 30; the event and log streams keep their own limit. Sign-in and sign-out time out the same way. After a read timeout, Retry fetches the data again. A write timeout says the change may have been applied and asks for a reload before trying again. (#104, #118)
- Apply and reload is disabled when a refetch makes the open source read-only. Undo after Cancel no longer restores the discarded edits. (#101, #106)
- The must switch in the new-rule dialog aligns with the outbound picker. (#90)
- A connection opened by its link unfolds its collapsed group, and so does a selected connection that moves into another folded group. Outbound groups no longer unfold when the language changes, and an outbound named like a built-in label keeps its own group. (#93, #118)
- When an ordinary rule precedes the must rules in the routing block, doona's refusal to switch the outbound mode says to move the must rules to the top and names the rule. (#103)
- Trace field errors wait until a field is filled. Chrome no longer reports `apple-mobile-web-app-capable` as deprecated. (#103)
- Help buttons and status lights align with the centre of their text. (#98)
- Logs and the flow distribution say when the configuration forbids their recorder. Test all no longer blames TCP probe support when it is unavailable for another reason. (#98)
- The minimum password length applies only to the administrator password created at setup, not to signing in. (#107)
- A failed suspend or resume shows its translated message again (`lifecycle_failed`). (#115)
- Overview no longer gives honk's causes and fixes for resources an older backend leaves out of its capabilities; they are listed as not provided by the build. When another engine gives no reason, a read-only main configuration no longer claims one. (#118, #132)
- A read-only source is labelled as containing secrets only when its text defines a `native_api` or `clash_api` block; otherwise it shows as read-only. (#118)
- The health-check URL dialog sends only the fields that were edited and offers the check settings that the group's `mutable_config` lists. A save no longer replaces a change another client made to the same field: it fails as a conflict and the dialog stays open. (#106, #118, #132)
- The new-source dialog warns that a path is not included only when no loaded file includes it, and resolves include patterns from the main configuration's directory, as honk does. (#118, #131)
- A geodata update whose result cannot be confirmed is shown as unknown, not as failed. (#106)
- A new source whose read-back fails stays created, and a late result no longer reaches a reopened new-file dialog. A selected diagnostic stays selected across polls. In the demo, a new source whose name has a space, a non-ASCII character or `?` opens once created. (#106)
- The demo refuses source writes over honk's size limits, a second create of the same path and a create past the source limit, as honk does. Demo sign-in works over plain HTTP on a LAN address, where browsers do not provide `crypto.randomUUID`. (#118, #124, #131)
- The DNS device filter error appears under its field and is read with it by screen readers. The DNS log's time column fits relative times. (#105, #106)
- The note on the Arrange tab of Policies no longer mentions an Add menu on each row; it points to Add to group below the list and to Review and apply. (#111)

### For contributors

- CONTRIBUTING describes the architecture and the import allow-lists, and lint enforces the engine boundary. (#123)
- `tools/honk-commit.txt` pins the honk commit a release bundles; the release workflow fails unless honk's `debug` release, its target and its source tag name that commit. (#117)
- The API contract is pinned at api-standardize 3640713. (#116)
- The store, the configuration page, the engine explanations, the sign-in outcomes and the connection test were split into smaller modules, and unused code and duplicate strings were removed, without changing behaviour. (#108, #119, #120, #121, #126, #129)

## [0.1.0-beta.7] - 2026-09-27

### Added

- Overview shows the backend process's CPU usage.
- Connections shows each connection's upload and download rates, calculated from successive samples.
- Policies lets you edit a group's health-check URL.
- Configuration can create a new source file when the backend supports it.
- A failed first fetch of a new subscription offers Retry in its toast; a new build offers Reload. Toasts with actions remain until dismissed or used.
- Settings lets you place notifications at the top or bottom, centred or aligned to the end.

### Changed

- Toasts keep their status colours and separate the summary from backend details. Show all and action buttons share a footer on desktop and phones; request IDs stay in the console instead of the toast.
- Desktop tabs are 34 pixels tall, name lists use consistent sorting, and equally sized connection filter groups keep a stable order.
- Configuration shows module sections from read-only includes and groups repeated diagnostics.
- README screenshots reflect the current desktop and phone layouts in all three languages.

### Fixed

- Configuration completion reads groups from every source and preserves each group header's original quotes. Quick setup preserves the same names in generated routing rules.
- After a conflicting source save, the editor keeps the draft and uses the refreshed source as its next save's base. Reloading clears validation results from the previous generation.
- Activity finds the outbound mode line by its marker rather than its position in the file.
- DNS rejects an invalid device address without dropping the last valid filter. Closing one connection no longer clears another connection opened while the request was pending.
- The routing map waits for its nodes before settling. Connection rates discard baselines from lists no longer held by the store.
- Retrying a refused event stream reconnects it, recovered capability errors clear, and a refused first-page request is not repeated without a cursor.
- Settings can sign in again after signing out, distinguishes a rejected token from a connection failure, and reports unavailable session storage as a storage error.
- Geodata preset changes ask for confirmation when they lack categories used by the configuration. Operation errors identify the failed stage when the backend provides it.
- Paused logs show the held record count. Gap summaries omit a zero dropped count, and Activity notice summaries align in one column.
- Long backend versions end with an ellipsis; available backend capabilities use a status dot.
- A pending keyboard navigation prefix clears when the filter shortcut has no field to focus, and near-viewport content keeps its observer across callback changes.

## [0.1.0-beta.6] - 2026-09-26

### Added

- The side navigation shows the connected backend's name and version with a connection light. It opens a card with the connection state, API, build and backend URL, and buttons for About doona and for editing the backend in Settings. On phones the same card opens from the overflow menu.
- About states that doona talks only to the backend it is connected to and sends nothing elsewhere.
- Settings offers a mirrored layout for left-handed use.
- A right-to-left language lays the page out right to left; adding one needs only its catalogue.
- Node latencies carry a green, yellow or red dot, which keeps the tone visible in palettes that show latency text in the body colour.
- Hovering or tapping an Activity sparkline shows the sample's value and time.
- On touch screens, a tap reveals the full text of a truncated table cell.

### Changed

- On phones, the Connections filter field takes the toolbar row and the other filters fold into one menu.
- On phones, the busiest connection takes a row of its own, and a host too long for it keeps its end visible.
- On small phones, key-value facts use two columns, truncated drawer values wrap, table row actions stay reachable, and the column resizer is wider.
- On phones, the Activity node picker stays inside its tile, custom geodata URL fields use the full width, and the subscription remove button stays on its row.
- On short landscape phones, the top bar scrolls away instead of covering the page.
- A tab bar that overflows scrolls the selected tab into view and fades its cut edge.
- The Arrange hint no longer says the tray is on the right when it is below the groups.
- Heatmap time marks are larger.
- Translations use one term per concept, the English copy is tidier, several mistranslations are corrected, and Simplified Chinese distinguishes blocking from DNS interception.
- CONTRIBUTING describes how to correct a translation and how to propose a new language.

### Fixed

- A routing trace simulates the first IPv4 and first IPv6 answer and shows the full resolution, instead of refusing a name with several addresses.
- Buffer overflow gaps no longer appear on the Activity home card; Events still lists them.
- A configuration write the backend accepted is reported as unknown, not failed, when the following status poll fails.
- The add-rule dialog preselects no outbound until the groups are read, instead of showing a wrong one.
- Donut charts with more than sixty slices no longer draw a slice with a negative angle.
- Chart tooltips are announced politely, so moving through a chart does not interrupt the screen reader.
- A gap summary that names no record starts at its reason instead of a dash.
- Chart tooltips stay inside their card on narrow phones.

## [0.1.0-beta.5] - 2026-09-26

### Added

- Settings shows geodata presets, custom source URLs, automatic updates, a download route and update status when the backend supports them.
- The Connections Traffic tab shows node latency, including P50 and P90 across nodes and which nodes carry current connections, when health data is available.
- When rules are writable, connection details can create a routing rule from the destination and apply it immediately or hold it for later. A matched-rule link opens the rule list.
- The add-subscription dialog offers the refresh interval, User-Agent and cache option when the backend advertises them.
- Navigation groups pages into Overview, Traffic, Routing and Settings hubs, with a bottom bar on phones.
- The top bar has a separate reload action and shows the number of held rules to apply.
- Settings shows manual installation steps for Safari on iPhone and iPad, and Safari 26 or later on macOS, when no install prompt is available.

### Changed

- Until a language is chosen, doona follows the browser's first language preference; a saved choice still takes precedence.
- The Connections and flow records tables show the final node or outbound instead of the full chain. Details and CSV export retain the chain, a tooltip shows the path when a group precedes the node, and a saved hidden column stays hidden.
- Geodata settings save as they change. Custom URLs remain editable when their initial values came from the configuration file; restarting honk can restore URLs named in that file.
- Segmented controls that do not fit become a picker instead of scrolling or clipping.
- On narrow Activity tiles, sparklines sit below the value and use the tile width.
- On phones, top-bar options use submenus, and longer page action groups move extra actions into a menu.
- Initial page loads download less shell code, and visitors using a real backend no longer download demo code for offline use.
- Activity charts download less JavaScript. In measured large-list scenarios, node searches and probes, connection sorting and selection, and log bursts use less scripting time.
- The README includes a page tour and phone guidance, and demo links point to https://demo.daeuniverse.org/.
- Internal restructuring of charts, shared components, routes and styles leaves the UI and behavior unchanged.

### Fixed

- Restart-only configuration refusals name the affected settings, and a file written without a successful reload is reported as unapplied.
- Repeated configuration conflicts explain when the file on disk differs from the running configuration.
- Runtime settings refresh after activation, and retries no longer replay writes without an idempotency key. Configuration validation and routing traces, which write nothing, still retry after a temporary refusal.
- DNS statistics stay usable when a log page is refused for size. Failed reads show one retryable error, and early-ended pages show how many records loaded without assuming why they ended.
- Close all handles connection sets above the backend's bulk limit in batches and reports connections left open when a batch stops.
- Configuration validation and writes report the advertised size limit before sending an oversized request.
- Relative times and traffic and memory chart windows use the backend host's observed time when it is available.
- Event and log streams reconnect after missed heartbeats. Gaps from expired cursors are marked, including in exported logs.
- Unknown operation and probe results are shown as unknown instead of failed or unreachable; new backend enum values are shown instead of blank labels.
- Policies, fallback groups, recorded log levels, delayed retries and degraded subscription refreshes are described according to the backend's actual behavior. Known backend error codes have translations.
- Module diagnostics stay in place while typing and when switching sections, and code scrolled sideways no longer shows through the line-number gutter.
- Password sign-in works with the backend's public discovery response.
- The demo's traffic history advances with time, so Activity charts retain a full recent window after a tab has been in the background.
- The demo keeps refused settings patches atomic, updates required geodata categories after configuration changes and redacts secret-bearing parts of geodata URLs.
- Connection rules can be placed before the earliest writable rule. Rule creation waits for groups to load, and the matched-rule link remains available on read-only configurations.
- A rule value containing parentheses or `&&` is refused, because honk would read it as rule syntax.
- Held rules cannot be discarded or applied concurrently while an apply is running. Written rules leave the pending list even if reload fails or its result is unknown, and partial results count every written rule.
- Geodata controls follow backend capabilities, including older backends without download-route settings. Custom URLs cannot be edited while saving, so later input is not lost.
- DNS cache usage is read again after a flush or deletion; an older cache walk cannot restore stale usage afterward.
- Chart arrow keys keep working after the data shrinks. The Outbound downloads chart has one named keyboard stop, and its tooltip no longer sits under the centre total.
- Keyboard focus stays on a segmented control when resizing switches it between buttons and a picker.
- On phones, the bottom bar and the hub page switcher replace the history entry, so Back no longer retraces every tap.
- An arrow key pressed right after a phone submenu opens is no longer undone.
- A popover opened near the right edge keeps its width instead of shifting while it is placed.
- Screen readers announce a retry wait once instead of every second.
- A failed node read shows an error in the Connections latency card instead of silently removing it.
- Table columns and page width stay steady while rows load, tables change layout or pages change height.
- Table lines, row hover and other quiet fills stay visible on cards in the Rosé Pine dark, Nord and Kary palettes, and touching a chart point no longer leaves a hover state stuck.

## [0.1.0-beta.4] - 2026-09-24

### Added

- dae text outside the editor is highlighted with the editor's colours, in policy arrangement, rules, the configuration wizard, configuration issues and flow details.

### Changed

- Release assets carry the upstream version without `v`, and each package keeps its own format's version inside: `0.1.0~beta.4-1` for deb, rpm and ipk, `0.1.0beta4` for Arch.
- The API contract is pinned to the upstream api-standardize `honk` branch, which now includes rule sources named by id, recorder modes, password sign-in and DNS cache usage.
- Package recipes list every architecture and declare the licences of the bundled npm packages; the Gentoo ebuild maps alpha, beta and rc versions to their tags.

### Fixed

- The outbound mode card shows the current mode, read-only with the reason, when the main configuration cannot be written.
- The dae highlighter no longer colours digits inside names as numbers and keeps an address or CIDR as one number.

## [0.1.0-beta.3] - 2026-09-24

### Added

- A public demo on GitHub Pages with sample data from the built-in mock backend.
- A clear message when an engine has no native API, instead of a token prompt.

### Changed

- Releases no longer include a node_modules archive; package recipes install the prebuilt tarballs.
- The READMEs and guides state which honk builds serve the native API and lead with password sign-in.
- Card values keep secondary facts on a caption line, cards in a row stay equal in height, and the capabilities list uses columns.

### Fixed

- An updated build could miss the page language for offline start.
- The Events page left out events received before it opened.
- Layout on tablets and phones for Overview, DNS, the routing map and other pages.
- Sticky table headers and overlays showed content through them in the glass palette.
- Untranslated datapath errors and the rule editor's must switch.

## [0.1.0-beta.2] - 2026-09-24

### Added

- Password setup, sign-in and sign-out for supported backends.
- Group membership editing and group ordering by drag or menu.
- DNS query analysis and cache status, node latency charts, connection traffic plots and log level heatmaps.
- Configuration module editing, recorder settings and links from module cards to their sources.

### Changed

- Show routing as a device-aware tree and open a rule editor from a flow.
- Keep data tabs mounted and use shared fact cards, labels and confirmation dialogs.
- Provide Alpine, OpenWrt, Gentoo, Nix and nfpm package recipes for this beta release.

### Fixed

- Keep source edits within their rules or fields and validate typed values before writing them.
- Preserve each tab's backend session, show failed reads in place and keep loading layouts stable.
- Report DNS cache usage by entry count and cache only the active language for offline use.

### Performance

- Load search, page code and language fonts when needed; reuse warm pages.
- Reduce idle polling and event refetches, retain unchanged results and virtualize longer lists.

## [0.1.0-beta.1] - 2026-09-21

### Added

- A virtualized connections table, flow graph, rule distribution and richer runtime views.
- A configuration editor with validation, diagnostics, quick setup and rule editing.
- Subscription and node management, live logs, backend settings and search across pages.
- Installable offline shell, multilingual messages and release archives with optional fonts.

### Changed

- Consolidate the interface around the native API and shared controls.
- Show retained flows, rule distribution, traffic history and backend capabilities in the product pages.
- Package the beta for distribution and verify archive checksums in the release workflow.

### Fixed

- Guard unsaved configuration changes and hidden routes, and keep streams reconnecting after interruptions.
- Match live backend resource limits and operation responses.

### Performance

- Load feature pages on demand and virtualize the connections table and long node menus.

## [0.1.0-alpha.2] - 2026-09-15

### Added

- A typed native API client, contract-backed mock and resource hooks.
- Connection and flow details, per-network policy selection, routing traces and live events.
- DNS cache actions, runtime controls, traffic history and outbound usage.
- More light and dark palettes, a glass theme and a validation page.

### Changed

- Replace fixture-backed page data with native API operations and capability-aware navigation.
- Keep the glass theme on a gradient wallpaper after trying photo wallpapers.

### Fixed

- Apply the saved palette before first paint and keep long menus from scrolling sideways.
- Show diagnostic reasons and error counts clearly in validation.

### Performance

- Filter and virtualize large node lists and load picker sections in pages.

## [0.1.0-alpha.1] - 2026-09-15

### Added

- An activity dashboard and a themed shell with Rosé Pine, Catppuccin and Nord palettes.
- Themed tables, forms, dialogs, tabs, detail cards and status displays across the initial pages.

### Changed

- Adapt the top bar, cards and controls to narrow screens.
- Align control sizes, links, separators and alert dialogs with the shared UI kit.

### Fixed

- Keep table columns and action cells visible and prevent cards and controls from overflowing.

[0.1.0-beta.8]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.7...v0.1.0-beta.8
[0.1.0-beta.7]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.6...v0.1.0-beta.7
[0.1.0-beta.6]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.5...v0.1.0-beta.6
[0.1.0-beta.5]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.4...v0.1.0-beta.5
[0.1.0-beta.4]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.3...v0.1.0-beta.4
[0.1.0-beta.3]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.2...v0.1.0-beta.3
[0.1.0-beta.2]: https://github.com/Zakkaus/doona/compare/v0.1.0-beta.1...v0.1.0-beta.2
[0.1.0-beta.1]: https://github.com/Zakkaus/doona/compare/v0.1.0-alpha.2...v0.1.0-beta.1
[0.1.0-alpha.2]: https://github.com/Zakkaus/doona/compare/v0.1.0-alpha.1...v0.1.0-alpha.2
[0.1.0-alpha.1]: https://github.com/Zakkaus/doona/releases/tag/v0.1.0-alpha.1
