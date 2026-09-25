<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.svg">
  <img src="docs/logo-light.svg" width="104" alt="doona">
</picture>

# doona

**Web UI for the [daeuniverse](https://github.com/daeuniverse) engines: nodes, groups, rules and the configuration, from a browser.**

English · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md)

[Install](#install) • [First run](#first-run) • [Pages](#pages) • [Development](#development) • [Guide](docs/guide.md)

</div>

doona is a static web UI for the native API the daeuniverse engines share: honk today, dae once it implements the same contract. The engine serves it itself or any web server does; it shows what the engine is doing and manages nodes, groups, routing rules and configuration files.

[Try the demo with sample data](https://zakkaus.github.io/doona/).

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
VERSION=v0.1.0-beta.4  # replace with the downloaded release tag
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
