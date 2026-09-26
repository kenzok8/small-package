<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.svg">
  <img src="docs/logo-light.svg" width="104" alt="doona">
</picture>

# doona

**Web UI for the [daeuniverse](https://github.com/daeuniverse) engines: nodes, groups, rules and the configuration, from a browser.**

English · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md)

[Install](#install) • [First run](#first-run) • [Pages](#pages) • [Page tour](#page-tour) • [On a phone](#on-a-phone) • [Development](#development) • [Guide](docs/guide.md)

</div>

doona is a static web UI for the native API the daeuniverse engines share: honk today, dae once it implements the same contract. The engine serves it itself or any web server does; it shows what the engine is doing and manages nodes, groups, routing rules and configuration files.

[Try the demo with sample data](https://demo.daeuniverse.org/).

![The activity page](docs/screenshots/en/activity-light.webp)

<details>
<summary><strong>Every palette</strong></summary>

Eleven palettes support light and dark modes; Rosé Pine and Catppuccin include multiple dark flavours. Use the palette picker in the top bar.

<img src="docs/screenshots/palettes.webp" alt="Every palette in light and dark" width="100%">

</details>

## Theme gallery

The activity page in four palettes. Select a palette and mode from the top bar.

| Theme gallery | Light                                                                | Dark                                                               |
| ------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Rosé Pine     | ![Rosé Pine Light](docs/screenshots/en/theme-rose-pine-light.webp)   | ![Rosé Pine Dark](docs/screenshots/en/theme-rose-pine-dark.webp)   |
| Catppuccin    | ![Catppuccin Light](docs/screenshots/en/theme-catppuccin-light.webp) | ![Catppuccin Dark](docs/screenshots/en/theme-catppuccin-dark.webp) |
| Nord          | ![Nord Light](docs/screenshots/en/theme-nord-light.webp)             | ![Nord Dark](docs/screenshots/en/theme-nord-dark.webp)             |
| Glass         | ![Glass Light](docs/screenshots/en/theme-glass-light.webp)           | ![Glass Dark](docs/screenshots/en/theme-glass-dark.webp)           |

## Status

doona targets the native API implemented by honk's `feat/native-api` branch; that API is not released yet. The contract it is built against is pinned in [SOURCE.md](contract/api-standardize/SOURCE.md). Backends that omit newer resource keys are accepted: doona fills those keys as unavailable. With no backend configured, a built-in mock supplies demo data; every screenshot here shows the mock.

## Install

Release archives (`doona-<version>.tar.gz`, the optional `doona-fonts-<version>.tar.gz` with Noto Sans TC and SC, and `SHA256SUMS`) are attached to tags on the [releases page](https://github.com/Zakkaus/doona/releases); until the first tag, build them yourself as described under [Development](#development). Verify and extract the files into the directory the engine or web server will serve:

```sh
VERSION=v0.1.0-beta.5  # replace with the downloaded release tag
sha256sum --ignore-missing -c SHA256SUMS
sudo mkdir -p /usr/share/doona
sudo tar -xzf "doona-${VERSION}.tar.gz" -C /usr/share/doona
if [ -f "doona-fonts-${VERSION}.tar.gz" ]; then
    sudo tar -xzf "doona-fonts-${VERSION}.tar.gz" -C /usr/share/doona
fi
```

### Native API requirement

**Required honk build:** doona needs the native API in [Glassyiris/honk `feat/native-api`](https://github.com/Glassyiris/honk/tree/feat/native-api). No tagged daeuniverse/honk release includes it yet. The `native_api` and `password_auth` keys may change before upstream release. A released honk returns 404 for `/api` and `/ui/`. The configuration below applies to that branch.

honk's native API is opt-in. Point `ui` at the extracted files and honk serves them at `/ui/`, same-origin with the API:

```dae
experimental {
    native_api {
        enabled: true
        listen: '127.0.0.1:9527'
        password_auth: true
        ui: '/usr/share/doona'
    }
}
```

Keep this block in its own include (`include { api.dae }`) so the main file stays editable from the configuration page. For scripts and automation, use `secret: '<random token>'` instead of `password_auth: true`. Requirements, serving from another web server or a reverse proxy, and the distribution packages are in the [guide](docs/guide.md#install).

## First run

Open `/ui/` on the engine host. On a first visit doona asks the origin it was served from for `/api` and saves the engine as a backend. In password mode, the locked sign-in dialog offers first-time setup to create the administrator; complete setup from a loopback or private-network client, then sign in with the username and password. Served from elsewhere, or to reach another engine, open Settings and enter the server root.

In token mode, doona asks for the token. Enter it in Settings with the server root, or use a pairing link such as `/ui/#/settings?api=http://router:9527&token=…` to fill the form; doona removes the token from the address bar on load.

The activity page then shows the running engine. Add a subscription or paste share links on Nodes, pick or pin members on Policies, add rules on Rules, and edit, validate and reload the sources on Configuration. Every write goes through the engine with the hash doona read the source at, and a failed reload keeps the previous generation active. The [guide](docs/guide.md#first-run) walks through each page.

## Pages

<img src="docs/screenshots/en/policies-light.webp" alt="The policies page" width="100%">

| Page          | Shows                                                                                                           |
| ------------- | --------------------------------------------------------------------------------------------------------------- |
| Activity      | Outbound mode, traffic and memory, active connections, node latency, outbound usage, top clients, notifications |
| Overview      | Engine and eBPF state, traffic counters, backend capabilities, the status as JSON                               |
| Connections   | Live connections with source, destination, rule, chain and traffic; close one or all                            |
| DNS           | Queries with their answers, the cache, the log; a flush                                                         |
| Policies      | Groups, their members and health; selection, pinning, probing and editing                                       |
| Rules         | A routing tree from rules or devices through outbounds to nodes, the rule list with hits, the flow log, a trace |
| Nodes         | Subscriptions and their refresh interval, inline nodes, add and remove, probe and join a group                  |
| Configuration | Sources with diagnostics, an editor with validation, quick setup and export                                     |
| Events, Logs  | The backend event stream; the log stream with filters, pause and export                                         |
| Settings      | Backends, runtime settings and backend actions, language, appearance and palette                                |

A page is marked unavailable only when every resource it needs is unavailable. `Ctrl K` searches pages, connections, nodes, groups, rules and sources from anywhere. Which resources each page needs, and where doona keeps its own settings, are in the [guide](docs/guide.md#pages).

<img src="docs/screenshots/en/rules-light.webp" alt="The rules page" width="100%">

## Page tour

### Arranging groups

On the Arrange tab of Policies, drag a node or a subscription from the list on the right onto a group to add it. The Add menu on each row and keyboard dragging do the same.

<img src="docs/screenshots/en/arrange.webp" alt="Dragging the node us-01 onto the gaming group" width="100%">

### Traffic and connections

The Traffic tab of Connections plots each connection's upload against its download, coloured by outbound; select a point to open that connection. The Connections tab groups live connections by device or by outbound, filters them by protocol and outbound, and exports them as CSV.

<img src="docs/screenshots/en/connections-traffic.webp" alt="The Traffic tab of the connections page" width="100%">

<img src="docs/screenshots/en/connections-list.webp" alt="Live connections grouped by device" width="100%">

### DNS

The Statistics tab shows the median and P95 resolution time, the cache hit rate and the failure rate. The charts below place each upstream's lookups on a latency scale and count how the queries ended.

<img src="docs/screenshots/en/dns.webp" alt="The Statistics tab of the DNS page" width="100%">

### Log activity

Above the log list, a heatmap counts records per level over time. A level's row header sets the minimum level the list shows.

<img src="docs/screenshots/en/logs.webp" alt="The log activity heatmap" width="100%">

### Routing map

The routing map on Rules follows traffic from rules, or from devices, through outbounds to nodes. Point at or select a rule, outbound or node to highlight the paths through it.

<img src="docs/screenshots/en/routing.webp" alt="Selecting a rule and then a node on the routing map" width="100%">

### Node latency

The Latency tab of Nodes plots each node's latest latency, moving average and average of the last 10 measurements. A switch groups the nodes by policy group or by protocol; unavailable nodes appear under their group.

<img src="docs/screenshots/en/latency.webp" alt="The Latency tab of the nodes page" width="100%">

## On a phone

Below 1024 pixels wide, the side navigation becomes a bottom bar with four hubs: Overview, Traffic, Routing and Settings. A hub opens on the page last viewed in it during the session, and its pages sit in a row above the content. Language, theme, palette and wordmark move into the top bar's overflow menu, a submenu each.

Tables drop the columns that do not fit, in a set order, and toolbars wrap onto more rows. On Overview, DNS and Logs, the first page action stays a button and the rest move into a menu.

Over HTTPS or on localhost, doona installs as an app. In Chrome and Edge, the About card in Settings offers Install as an app. Safari has no install prompt, so the card shows the steps instead. On iPhone and iPad, tap Share, then Add to Home Screen. In Safari 26 on macOS, choose File > Add to Dock.

<img src="docs/screenshots/en/phone.webp" alt="doona on phones: the connections table, the overflow menu and its palette submenu" width="100%">

## Development

```sh
pnpm install --frozen-lockfile
pnpm build                       # writes dist/
pnpm check                       # types, lint, translations, formatting, unit tests, generated API types
pnpm check:size                  # gzip budgets for the dist/ build
pnpm e2e:install --with-deps     # once, for the browser tests
pnpm e2e                         # rebuild, then test against the mock at the root and under /ui/
pnpm package                     # release/doona-<version>.tar.gz, doona-fonts-<version>.tar.gz, SHA256SUMS
```

`pnpm dev` serves the mock on Vite's dev server. The live-backend test run, the performance and screenshot tools, the source layout and the contract pin are described in the [guide](docs/guide.md#development); see [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Support

Report bugs and ask questions in the [issues](https://github.com/Zakkaus/doona/issues). Report backend issues to the connected engine's project: [honk](https://github.com/daeuniverse/honk) or [dae](https://github.com/daeuniverse/dae). See [SECURITY.md](.github/SECURITY.md) for reporting a vulnerability.

## License and credits

[GPL-3.0-only](LICENSE). Noto Sans TC and SC are under the [Open Font License](public/fonts/OFL.txt); [NOTICE](NOTICE) credits the Adobe Spectrum icons (Apache-2.0). The duck is the maintainer's own artwork.
