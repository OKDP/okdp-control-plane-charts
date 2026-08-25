<p align="center">
  <a href="https://okdp.io">
    <img src="https://raw.githubusercontent.com/OKDP/okdp.io/master/src/assets/logos/okdp-inverted.png" alt="OKDP: Open Kubernetes Data Platform" height="180" />
  </a>
</p>

[![ci](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/ci.yml/badge.svg)](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/ci.yml)
[![release-please](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/release-please.yml/badge.svg)](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/release-please.yml)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

# OKDP Control Plane Charts

Helm chart deploying the OKDP control plane as a whole: the API server
([okdp-control-plane-server](https://github.com/OKDP/okdp-control-plane-server)) and the web
console ([okdp-control-plane-ui](https://github.com/OKDP/okdp-control-plane-ui)), wired together
with the platform (in-cluster API Service, kubauth OIDC client, ingress).

---

## Why this project

Each control-plane component ships its own Helm chart, released and published with the
component (`oci://quay.io/okdp/charts/okdp-control-plane-server`, `oci://quay.io/okdp/charts/okdp-control-plane-ui`).
Deploying the control plane then means installing two charts, keeping their versions aligned,
pointing the console at the right API Service and registering the console with the platform
OIDC provider by hand.

This repository provides a single chart, `okdp-control-plane`, that installs both components
in one release with the platform glue between them, and pins the pair of versions validated
together.

---

## What the project does

- **Helm chart `okdp-control-plane`** (`charts/okdp-control-plane/`): umbrella chart depending
  on the published `okdp-control-plane-server` and `okdp-control-plane-ui` charts, plus:
  - a stable `okdp-server` Service in front of the API server pods, so the console `/api`
    routing does not depend on the Helm release name;
  - the kubauth `OidcClient` of the console (`okdp-ui`), registering the console public URL as
    an allowed redirect URI;
  - a `helm test` pod checking the health endpoints of both components.
- **OCI package** `oci://quay.io/okdp/charts/okdp-control-plane`, published on release.

<!-- release-please rewrites the first version of each line in the block below,
     so the chart version has to come before the sub-chart versions on its row. -->
<!-- x-release-please-start-version -->
| Chart | Version | Control plane (`appVersion`) | Sub-charts |
|---|---|---|---|
| [`okdp-control-plane`](charts/okdp-control-plane) | `0.2.0` | `0.7.x` | `okdp-control-plane-server` 0.7.1, `okdp-control-plane-ui` 0.7.0 |
<!-- x-release-please-end -->

Repository layout:

- `charts/okdp-control-plane`: the chart (`Chart.yaml`, `values.yaml`, `templates/`, `ci/`).
- `docs/assets`: architecture diagram (`architecture.drawio`, `architecture.svg`).
- `.github/workflows`: CI, publish and release workflows.
- `.ct.yml`, `.ct-install.yml`, `.lintconf.yaml`: chart-testing and yamllint configuration.
- `release-please-config.json`, `.release-please-manifest.json`: release automation.

---

## Architecture

<p align="center">
  <img src="docs/assets/architecture.svg" alt="OKDP Control Plane Charts topology" />
</p>

> **OKDP deployment context:** the chart installs the console and the API server **in the
> same release**. The browser only talks to the console origin: nginx serves the static bundle
> and proxies `/api` to the in-cluster `okdp-server` Service, so no CORS is involved between the
> console and the API. The browser still calls kubauth directly to load the OIDC configuration,
> which is why kubauth must allow the console origin (see Requirements). The
> platform provides the ingress controller, cert-manager, the OIDC provider (kubauth) and the
> GitOps engine (KuboCD); the chart only registers the console with kubauth through an
> `OidcClient` and renders the Ingress of the console.

See the sub-chart repositories for the internals of each component, and the
[KuboCD documentation](https://github.com/kubotal/kubocd) for the `Context` and `Release`
model the server builds on.

---

## Requirements

To install the chart:

- a Kubernetes cluster, and [Helm](https://helm.sh/) >= 3.8 (OCI registries).
- the kubauth `OidcClient` CRD (`oidcclients.kubauth.kubotal.io`), unless
  `oidcClient.enabled=false`: the chart registers the console as an OIDC client, and the install
  fails while that CRD is absent.

For the control plane to work once installed:

- [KuboCD](https://github.com/kubotal/kubocd) and a `Context` holding the service catalog: the
  server reads the catalog from that `Context` and creates the `Release` resources KuboCD
  reconciles. Without it the pods start and the console loads, but `/api/capabilities` and
  `/api/platform-services` answer `500`, so the catalog is empty, no service can be deployed,
  and the console keeps the Identity area visible although the platform cannot serve it.
- [kubauth](https://github.com/kubotal/kubauth) as OIDC provider, at the URL set in
  `okdp-control-plane-ui.oidc.authority` and injected at container startup (a `Context`
  publishing `identity.oidc` overrides it). The browser loads the OIDC configuration from
  kubauth directly, so its ingress must allow the console origin in CORS
  (`nginx.ingress.kubernetes.io/cors-allow-origin`, e.g. `https://console.<ingress suffix>`);
  without it the console "Sign in" button does nothing.
- an ingress controller (`nginx` by default) and cert-manager with the ClusterIssuer named in
  `okdp-control-plane-ui.ingress.clusterIssuer`.
- metrics-server (optional, resource usage panels of the console).

The [okdp-control-plane-dev-sandbox](https://github.com/OKDP/okdp-control-plane-dev-sandbox)
provides all of the above on a local Kind cluster. Its kubauth only allows the local console
origin (`http://localhost:4200`) in CORS; allow the in-cluster console as well before installing
the chart:

```sh
kubectl patch release kubauth -n okdp-system --type merge \
  -p '{"spec":{"parameters":{"oidc":{"ingress":{"annotations":{"nginx.ingress.kubernetes.io/cors-allow-origin":"http://localhost:4200, https://console.okdp.dev-sandbox"}}}}}}'
```

Known-good baseline: chart `0.2.0` <!-- x-release-please-version -->
with `okdp-control-plane-server` `0.7.1` and `okdp-control-plane-ui` `0.7.0`, on a Kind cluster.
This is the version set validated by the maintainers.

### Toolchain tested

| Tool | Version |
|---|---|
| Helm | `3.18` |
| Kind | `0.27.0` |
| kubectl | `1.32.2` |
| chart-testing | `3.14` |

---

## Installation

Check the cluster provides what the control plane needs (see the requirements above); only the
`OidcClient` CRD has to exist for `helm install` to succeed:

```sh
kubectl get crd contexts.kubocd.kubotal.io releases.kubocd.kubotal.io oidcclients.kubauth.kubotal.io
```

Install the chart from the OKDP registry:

<!-- x-release-please-start-version -->
```sh
helm install okdp-control-plane oci://quay.io/okdp/charts/okdp-control-plane --version 0.2.0 \
  -n okdp-system --create-namespace \
  --set okdp-control-plane-ui.ingress.host=console.okdp.dev-sandbox
```
<!-- x-release-please-end -->

Once the pods are `Running`, check the release and open the console:

```sh
kubectl get pods -n okdp-system -l app.kubernetes.io/instance=okdp-control-plane
helm test okdp-control-plane -n okdp-system
```

The console is available at `https://console.okdp.dev-sandbox` (on the dev sandbox:
`useradmin` / `password`).

---

## Cleanup

Remove the Helm release, and the namespace if it was created only for this install:

```sh
helm uninstall okdp-control-plane -n okdp-system
kubectl delete namespace okdp-system
```

---

## Development

Clone the repository, resolve the sub-charts and install from the local checkout:

```sh
git clone https://github.com/OKDP/okdp-control-plane-charts.git
cd okdp-control-plane-charts
helm dependency update charts/okdp-control-plane
helm install okdp-control-plane charts/okdp-control-plane -n okdp-system --create-namespace
```

Lint and test the chart the way CI does:

```sh
helm lint charts/okdp-control-plane
ct lint --config .ct.yml --all --check-version-increment=false
kind create cluster && ct install --config .ct-install.yml --namespace default
helm-docs -c .
```

`ct install` uses the values in `charts/okdp-control-plane/ci/` (kubauth `OidcClient` disabled,
as the CRD is absent on a bare cluster).

Console development against the same cluster (`npm start` on `localhost:4200`) needs the dev
origins on the OIDC client:

```sh
--set 'oidcClient.extraRedirectURIs={http://localhost:4200,http://localhost:4200/,http://localhost:4200/silent-refresh.html}'
```

### Upgrade the control-plane version

The chart pins the sub-chart versions in `Chart.yaml` (`dependencies[].version`) and
`appVersion`. To ship a new control-plane release, bump them, run
`helm dependency update charts/okdp-control-plane`, commit `Chart.lock` and open a pull request
with a conventional commit message (`feat: ...`); release-please proposes the chart version bump.

---

## Configuration

All values of the sub-charts are exposed under the `okdp-control-plane-server:` and
`okdp-control-plane-ui:` keys; the most
common ones are listed in [values.yaml](charts/okdp-control-plane/values.yaml) and every value
is documented in the [chart README](charts/okdp-control-plane/README.md). Chart-specific
settings:

| Value | Default | Description |
|---|---|---|
| `okdp-control-plane-ui.ingress.host` | `console.okdp.dev-sandbox` | Public host of the console |
| `okdp-control-plane-ui.ingress.clusterIssuer` | `default-issuer` | cert-manager ClusterIssuer of the console certificate |
| `okdp-control-plane-ui.backend.service` | `okdp-server` | Name of the stable Service rendered in front of the API server pods |
| `okdp-control-plane-ui.oidc.authority` | `https://kubauth.okdp.dev-sandbox` | OIDC issuer of the console, injected at container startup |
| `okdp-control-plane-ui.identity.adminRole` | `admins` | Role opening the administration pages (in the `groups` claim) |
| `okdp-control-plane-server.configuration.*` | see values | Server environment (platform namespace, KuboCD context, log level, ...) |
| `oidcClient.enabled` | `true` | Create the kubauth `OidcClient` of the console |
| `oidcClient.namespace` | `okdp-control-plane-server.configuration.platformNamespace` | Namespace of the `OidcClient` (kubauth clients namespace) |
| `oidcClient.publicUrl` | `https://<okdp-control-plane-ui.ingress.host>` | Console URL registered as redirect URI |
| `oidcClient.extraRedirectURIs` | `[]` | Extra redirect URIs (console development) |

---

## Contributing & License

Contributions follow the [OKDP contribution guide](https://github.com/OKDP/.github/blob/main/CONTRIBUTING.md). Released under the [Apache License 2.0](LICENSE).

---

**Built 🚀 for the OKDP Community**
<a href="https://okdp.io">
  <img src="https://okdp.io/okdp-notext.svg" height="20px" style="margin: 0 2px;" />
</a>
