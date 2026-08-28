# okdp-control-plane

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.7.1](https://img.shields.io/badge/AppVersion-0.7.1-informational?style=flat-square)

OKDP control plane - API server and web console deployed together

This chart is an umbrella over the two control-plane charts published by the
component repositories, plus the platform glue needed to run them together:

| Component | Sub-chart | Source |
| --- | --- | --- |
| API server (Go, REST + SSE, drives KuboCD) | [`okdp-control-plane-server`](https://quay.io/repository/okdp/charts/okdp-control-plane-server) | [okdp-control-plane-server](https://github.com/OKDP/okdp-control-plane-server) |
| Web console (SPA served by nginx, ingress) | [`okdp-control-plane-ui`](https://quay.io/repository/okdp/charts/okdp-control-plane-ui) | [okdp-control-plane-ui](https://github.com/OKDP/okdp-control-plane-ui) |

On top of the sub-charts it renders:

- a stable `okdp-server` Service (name configurable with
  `okdp-control-plane-ui.backend.service`)
  in front of the API server pods, so the console `/api` routing does not depend
  on the Helm release name;
- optionally, the console's OIDC client created as a Kubernetes resource
  (`oidcClient.enabled`, off by default), for providers that register clients so;
- a `helm test` pod checking the health endpoints of both components.

## Prerequisites

To install the chart: a Kubernetes cluster, Helm >= 3.8, and an OIDC provider
(Keycloak, Dex, or any OpenID Connect one). Set its issuer URL in
`okdp-control-plane-ui.oidc.authority` and register a client there; the chart
assumes no provider and creates none. For providers that register clients as
Kubernetes resources, `oidcClient.enabled=true` creates it for you (needs its CRD).

For the control plane to work once installed:

- [KuboCD](https://github.com/kubotal/kubocd) and a `Context` holding the service
  catalog, which the server reads and writes `Release` resources against;
- the OIDC provider carrying the client `okdp-control-plane-ui.oidc.clientId`, with
  `https://<host>`, `https://<host>/` and `https://<host>/silent-refresh.html` as
  redirect URIs, and allowing the console origin. Sign-in is standard OpenID
  Connect, so the login, the catalog and the services work the same on any
  provider; only the console's Identity pages (users and groups) stay
  provider-dependent, needing a provider that exposes user and group management;
- an ingress controller (`nginx` by default) and cert-manager with the
  ClusterIssuer named in `okdp-control-plane-ui.ingress.clusterIssuer`;
- metrics-server (optional, resource usage panels).

Values for the [okdp-control-plane-dev-sandbox](https://github.com/OKDP/okdp-control-plane-dev-sandbox),
which provides all of it on a local Kind cluster, ship as `values-dev-sandbox.yaml`.

## Install

```bash
helm install okdp-control-plane oci://quay.io/okdp/charts/okdp-control-plane \
  --version 0.2.0 \
  -n okdp-system --create-namespace \
  --set okdp-control-plane-ui.ingress.host=console.example.com \
  --set okdp-control-plane-ui.oidc.authority=https://oidc.example.com
```

From a local checkout:

```bash
helm dependency update charts/okdp-control-plane
helm install okdp-control-plane charts/okdp-control-plane -n okdp-system --create-namespace \
  --set okdp-control-plane-ui.ingress.host=console.example.com \
  --set okdp-control-plane-ui.oidc.authority=https://oidc.example.com
helm test okdp-control-plane -n okdp-system
```

On the OKDP dev sandbox, use the values that ship with the chart instead:

```bash
helm install okdp-control-plane charts/okdp-control-plane -n okdp-system \
  --create-namespace -f charts/okdp-control-plane/values-dev-sandbox.yaml
```

Developing the console against the same cluster (`npm start` on `localhost:4200`)
needs the local origins as redirect URIs on the client. `values-dev-sandbox.yaml`
lists them; with another provider, add them there.

## Upgrade the control-plane version

The chart pins the sub-chart versions in `Chart.yaml` (`dependencies[].version`)
and `appVersion`. To ship a new control-plane release, bump these, run
`helm dependency update charts/okdp-control-plane` and commit the
updated `Chart.lock`.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://quay.io/okdp/charts | okdp-control-plane-server | 0.7.1 |
| oci://quay.io/okdp/charts | okdp-control-plane-ui | 0.7.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| oidcClient.accessTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.annotations | object | `{}` | Extra annotations added to the OidcClient. |
| oidcClient.description | string | `"OIDC client for the OKDP web console"` |  |
| oidcClient.displayName | string | `"OKDP Console"` |  |
| oidcClient.enabled | bool | `false` | Render the console's OIDC client as a Kubernetes resource. |
| oidcClient.extraRedirectURIs | list | `[]` | Additional allowed redirect URIs (e.g. http://localhost:4200 to develop the console against this cluster). |
| oidcClient.idTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.labels | object | `{}` | Extra labels added to the OidcClient. |
| oidcClient.name | string | `"okdp-ui"` | Name of the OidcClient resource. The provider uses it as client_id, so it must match `okdp-control-plane-ui.oidc.clientId`. |
| oidcClient.namespace | string | `""` | Namespace of the OidcClient. Defaults to okdp-control-plane-server.configuration.platformNamespace. |
| oidcClient.publicUrl | string | `""` | Public URL of the console. Defaults to `https://<okdp-control-plane-ui.ingress.host>`. |
| oidcClient.refreshTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.scopes[0] | string | `"openid"` |  |
| oidcClient.scopes[1] | string | `"profile"` |  |
| oidcClient.scopes[2] | string | `"email"` |  |
| oidcClient.scopes[3] | string | `"groups"` |  |
| oidcClient.scopes[4] | string | `"offline_access"` |  |
| okdp-control-plane-server | object | `{"configuration":{"allowedOrigins":"https://okdp-ui.example.com","kubocdNamespace":"kubocd-system","logLevel":"info","platformNamespace":"okdp-system"},"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/okdp/images/okdp-control-plane-server","tag":""},"resources":{},"service":{"port":8093,"type":"ClusterIP"}}` | Values passed to the okdp-control-plane-server sub-chart. |
| okdp-control-plane-server.configuration.allowedOrigins | string | `"https://okdp-ui.example.com"` | Single origin allowed by CORS on the API. The console itself is same-origin, so this only matters for callers on another origin; set it to `https://<okdp-control-plane-ui.ingress.host>` when it does. |
| okdp-control-plane-server.configuration.kubocdNamespace | string | `"kubocd-system"` | Namespace of the KuboCD controller. |
| okdp-control-plane-server.configuration.platformNamespace | string | `"okdp-system"` | Namespace hosting the platform components. |
| okdp-control-plane-server.enabled | bool | `true` | Deploy the API server. |
| okdp-control-plane-server.image.tag | string | `""` | Image tag. Empty means the sub-chart appVersion. |
| okdp-control-plane-ui | object | `{"backend":{"port":8093,"service":"okdp-server"},"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/okdp/images/okdp-control-plane-ui","tag":""},"ingress":{"className":"nginx","clusterIssuer":"default-issuer","host":"okdp-ui.example.com","tlsSecretName":"okdp-ui-tls"},"oidc":{"authority":"","clientId":"okdp-ui"},"resources":{},"service":{"port":4200,"type":"ClusterIP"}}` | Values passed to the okdp-control-plane-ui sub-chart. |
| okdp-control-plane-ui.backend.port | int | `8093` | Port of that Service. |
| okdp-control-plane-ui.backend.service | string | `"okdp-server"` | Name of the Service the console ingress routes /api to. The umbrella chart renders a Service with this name in front of the API server pods, so it does not depend on the release name. |
| okdp-control-plane-ui.enabled | bool | `true` | Deploy the web console. |
| okdp-control-plane-ui.image.tag | string | `""` | Image tag. Empty means the sub-chart appVersion. |
| okdp-control-plane-ui.ingress.clusterIssuer | string | `"default-issuer"` | cert-manager ClusterIssuer used for the TLS certificate. |
| okdp-control-plane-ui.ingress.host | string | `"okdp-ui.example.com"` | Public host of the console. |
| okdp-control-plane-ui.oidc.authority | string | `""` | Issuer URL of the OIDC provider the console authenticates against. Required: the sub-chart fails the render when it is empty. The chart does not assume any particular provider. |
| okdp-control-plane-ui.oidc.clientId | string | `"okdp-ui"` | Client id the console uses. The client must exist in the provider, with the console URL as an allowed redirect URI. |
| tests.image | string | `"busybox:1.37"` | Image used by the `helm test` connection check. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
