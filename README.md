[![ci](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/ci.yml/badge.svg)](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/ci.yml)
[![release-please](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/release-please.yml/badge.svg)](https://github.com/OKDP/okdp-control-plane-charts/actions/workflows/release-please.yml)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
<a href="https://okdp.io">
  <img src="https://okdp.io/logos/okdp-notext.svg" height="20px" style="margin: 0 2px;" />
</a>

`okdp-control-plane-charts` holds the Helm chart deploying the OKDP control plane
as a whole: the API server ([okdp-control-plane-server](https://github.com/OKDP/okdp-control-plane-server))
and the web console ([okdp-control-plane-ui](https://github.com/OKDP/okdp-control-plane-ui)),
wired together with the platform (kubauth OIDC client, ingress, in-cluster API Service).

## Charts

| Chart | Version | Description |
| --- | --- | --- |
| [`okdp-control-plane`](charts/okdp-control-plane) | `0.1.0` | OKDP control plane - API server and web console deployed together |

Each chart has its own `README.md`, `Chart.yaml`, `values.yaml`, and templates under `charts/<chart-name>/`.

## Install A Chart

Charts are published as OCI artifacts under the repository owner namespace:

```bash
helm pull oci://quay.io/okdp/charts/<chart-name> --version <version>
helm install <release-name> oci://quay.io/okdp/charts/<chart-name> --version <version>
```

For forks or organization copies, replace `okdp` with the lowercased GitHub repository owner.

You can also install directly from a local checkout:

```bash
helm dependency update charts/<chart-name>
helm install <release-name> charts/<chart-name> -f charts/<chart-name>/values.yaml
```

## Development

Run Helm lint for a single chart:

```bash
helm lint charts/<chart-name>
```

Run chart-testing for all charts:

```bash
ct lint --config .ct.yml --all --check-version-increment=false
```

Run install tests with chart-testing and a local Kubernetes cluster:

```bash
kind create cluster
ct install --config .ct-install.yml --namespace default
```

Generate chart documentation:

```bash
helm-docs -c .
```

## CI

The CI workflow:

- detects changed charts with chart-testing;
- lints charts with `ct lint`;
- tests chart installation on Kind with `ct install` (values from `charts/<chart>/ci/`);
- generates Helm README documentation with `helm-docs`;
- commits generated chart README changes when the workflow has write permission;
- packages every chart under `charts/`;
- pushes CI packages to `oci://ghcr.io/<owner>/charts`.

## Publishing

Publishing is done by `publish.yml`, which packages every chart under `charts/` and pushes release packages to `oci://quay.io/<owner>/charts`.

The publish workflow is triggered in two ways:

- `publish-on-merge` runs after a successful `ci` workflow on `main`;
- `release-please` runs after release PRs are merged and then triggers `publish.yml`.

Existing chart versions are skipped so unchanged charts do not fail the publish job.

The owner portion is derived from the GitHub repository owner in lowercase, so forks and organization copies publish under their own namespace.

Required repository or organization secrets: `REGISTRY_USERNAME`, `REGISTRY_ROBOT_TOKEN`
(optional variable `REGISTRY`, defaults to `quay.io`).

## License

[Apache License 2.0](LICENSE)
