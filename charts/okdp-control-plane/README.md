# okdp-control-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.6.0](https://img.shields.io/badge/AppVersion-0.6.0-informational?style=flat-square)

OKDP control plane - API server and web console deployed together

This chart is an umbrella over the two control-plane charts published by the
component repositories, plus the platform glue needed to run them together:

| Component | Sub-chart | Source |
| --- | --- | --- |
| API server (Go, REST + SSE, drives KuboCD) | [`okdp-server`](https://quay.io/repository/okdp/charts/okdp-server) | [okdp-control-plane-server](https://github.com/OKDP/okdp-control-plane-server) |
| Web console (SPA served by nginx, ingress) | [`okdp-ui`](https://quay.io/repository/okdp/charts/okdp-ui) | [okdp-control-plane-ui](https://github.com/OKDP/okdp-control-plane-ui) |

On top of the sub-charts it renders:

- a stable `okdp-server` Service (name configurable with `okdp-ui.backend.service`)
  in front of the API server pods, so the console `/api` routing does not depend
  on the Helm release name;
- the kubauth `OidcClient` of the console (`okdp-app`), registering the console
  public URL as an allowed redirect URI;
- a `helm test` pod checking the health endpoints of both components.

## Prerequisites

- Kubernetes cluster with [KuboCD](https://github.com/kubocd/kubocd) (`Context`
  and `Release` CRDs) and a `Context` holding the service catalog;
- [kubauth](https://github.com/kubotal/kubauth) as OIDC provider (the console is
  built against `https://kubauth.<ingress suffix>` with client id `okdp-app`);
- an ingress controller (`nginx` by default) and cert-manager with the
  ClusterIssuer named in `okdp-ui.ingress.clusterIssuer`;
- metrics-server (optional, resource usage panels).

The [okdp-control-plane-dev-sandbox](https://github.com/OKDP/okdp-control-plane-dev-sandbox)
provides all of the above on a local Kind cluster.

## Install

```bash
helm install okdp-control-plane oci://quay.io/okdp/charts/okdp-control-plane \
  --version 0.1.0 \
  -n okdp-system --create-namespace \
  --set okdp-ui.ingress.host=console.okdp.dev-sandbox
```

From a local checkout:

```bash
helm dependency update charts/okdp-control-plane
helm install okdp-control-plane charts/okdp-control-plane -n okdp-system --create-namespace
helm test okdp-control-plane -n okdp-system
```

Local development of the console (`npm start` on `localhost:4200`) against the
same cluster: add the dev origins to the OIDC client.

```bash
--set 'oidcClient.extraRedirectURIs={http://localhost:4200,http://localhost:4200/,http://localhost:4200/silent-refresh.html}'
```

## Upgrade the control-plane version

The chart pins the sub-chart versions in `Chart.yaml` (`dependencies[].version`)
and `appVersion`. To ship a new control-plane release, bump these, run
`helm dependency update charts/okdp-control-plane` and commit the
updated `Chart.lock`.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://quay.io/okdp/charts | okdp-server | 0.6.0 |
| oci://quay.io/okdp/charts | okdp-ui | 0.6.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| oidcClient.accessTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.annotations | object | `{}` | Extra annotations added to the OidcClient. |
| oidcClient.description | string | `"OIDC client for the OKDP web console"` |  |
| oidcClient.displayName | string | `"OKDP Console"` |  |
| oidcClient.enabled | bool | `true` | Create the kubauth OidcClient for the console. |
| oidcClient.extraRedirectURIs | list | `[]` | Additional allowed redirect URIs (e.g. http://localhost:4200 for local development of the console against this cluster). |
| oidcClient.idTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.labels | object | `{}` | Extra labels added to the OidcClient. |
| oidcClient.name | string | `"okdp-app"` | Name of the OidcClient resource. Kubauth uses it as client_id, which must match the client id built into the console (`okdp-app`). |
| oidcClient.namespace | string | `""` | Namespace of the OidcClient (kubauth clients namespace). Defaults to okdp-server.configuration.platformNamespace. |
| oidcClient.publicUrl | string | `""` | Public URL of the console. Defaults to `https://<okdp-ui.ingress.host>`. |
| oidcClient.refreshTokenLifespan | string | `"1h0m0s"` |  |
| oidcClient.scopes[0] | string | `"openid"` |  |
| oidcClient.scopes[1] | string | `"profile"` |  |
| oidcClient.scopes[2] | string | `"email"` |  |
| oidcClient.scopes[3] | string | `"groups"` |  |
| oidcClient.scopes[4] | string | `"offline_access"` |  |
| okdp-server | object | `{"configuration":{"allowedOrigins":"https://console.okdp.dev-sandbox","contextName":"default","contextNamespace":"kubocd-system","kubocdNamespace":"kubocd-system","logLevel":"info","platformNamespace":"okdp-system","releaseInterval":"30m","releaseTimeout":"10m"},"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/okdp/images/okdp-server","tag":""},"resources":{},"service":{"port":8093,"type":"ClusterIP"}}` | Values passed to the okdp-server sub-chart. |
| okdp-server.configuration.allowedOrigins | string | `"https://console.okdp.dev-sandbox"` | Single origin allowed by CORS. Kept for direct API access; the console itself is same-origin (the ingress routes /api to the server). |
| okdp-server.configuration.contextName | string | `"default"` | KuboCD Context holding the service catalog. |
| okdp-server.configuration.kubocdNamespace | string | `"kubocd-system"` | Namespace of the KuboCD controller. |
| okdp-server.configuration.platformNamespace | string | `"okdp-system"` | Namespace hosting the platform components (kubauth, OIDC clients). |
| okdp-server.enabled | bool | `true` | Deploy the API server. |
| okdp-server.image.tag | string | `""` | Image tag. Empty means the sub-chart appVersion. |
| okdp-ui | object | `{"backend":{"namespace":"","port":8093,"service":"okdp-server"},"enabled":true,"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/okdp/images/okdp-ui","tag":""},"ingress":{"className":"nginx","clusterIssuer":"default-issuer","host":"console.okdp.dev-sandbox","tlsSecretName":"okdp-ui-tls"},"oidc":{"enabled":false},"resources":{},"service":{"port":4200,"type":"ClusterIP"}}` | Values passed to the okdp-ui sub-chart. |
| okdp-ui.backend.namespace | string | `""` | Namespace of that Service. Empty means the release namespace. |
| okdp-ui.backend.port | int | `8093` | Port of that Service. |
| okdp-ui.backend.service | string | `"okdp-server"` | Name of the Service the console proxies /api to. The umbrella chart renders a Service with this name in front of the API server pods, so it does not depend on the release name. |
| okdp-ui.enabled | bool | `true` | Deploy the web console. |
| okdp-ui.image.tag | string | `""` | Image tag. Empty means the sub-chart appVersion. |
| okdp-ui.ingress.clusterIssuer | string | `"default-issuer"` | cert-manager ClusterIssuer used for the TLS certificate. |
| okdp-ui.ingress.host | string | `"console.okdp.dev-sandbox"` | Public host of the console. |
| tests.image | string | `"busybox:1.37"` | Image used by the `helm test` connection check. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
