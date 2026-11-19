## Рішення

**Синтаксичні помилки / опечатки**
- `Dockerfile`: `main:application` -> `main:app`. Flask називається `app`).
- `api-deployment.yaml`: ключ секрету `redis-uri` -> `redis-url` як у `secret.yaml`.
- `api-service.yaml`: selector `component: backend` -> `api`, інакше в сервісу не було endpoints.
- Ліміт пам'яті API 16Mi -> 160Mi, інакше OOMKill через брак меморі.

**Поплутані змінні та значення, порти etc**
- `APP_MODE` -> `APP_ENV`: застосунок читає `APP_ENV`.
- Порт API 8080 -> 8000 у `containerPort`, NetworkPolicy.
- Порт Redis у NetworkPolicy 6380 → 6379.
- `web.service.targetPort` -> 80. Caddy слухає `:80`.
- Пробі поміняні місцями: liveness -> `/api/health`, readiness -> `/api/ready`.
- `web.caddyRoot`: `/srv/www/build` -> `/srv/www/dist`. frontend збирає в `dist`.
- `ingress.stripApiPrefix: false`: маршрути застосунку вже починаються з `/api`.

**Доробки**

- `pullPolicy: IfNotPresent` для локальних образів: з `Always` kubelet тягнув їх із Docker Hub і показує `ErrImagePull`.
- Для gunicorn змонтований `emptyDir` у `/tmp`.
- Анотації `checksum/config` (api, web) і `checksum/secret` (api): зміна ConfigMap/Secret у `helm upgrade` сама перезапускає под.
- CI: до збірки образів додані `helm lint` і `helm template`.

### Перевірка

```bash
DESCRIPTION: Install complete
NAME: dashboard
LAST DEPLOYED: Thu Nov 19 14:26:47 2026
NAMESPACE: dashboard
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE:     dashboard-internal-dashboard-smoke
Last Started:   Thu Nov 19 14:27:00 2026
Last Completed: Thu Nov 19 14:27:13 2026
Phase:          Succeeded
```

```bash
NAME                                                 READY   STATUS      RESTARTS   AGE
dashboard-internal-dashboard-api-7dcf5b585f-6zn2j    1/1     Running     0          19m
dashboard-internal-dashboard-redis-84bd66d95-cpdlx   1/1     Running     0          19m
dashboard-internal-dashboard-smoke                   0/1     Completed   0          19m
dashboard-internal-dashboard-web-664b5bf77b-hwpfx    1/1     Running     0          19m
```

```bash
kubectl get pods,svc,ingress,endpoints,networkpolicy -n dashboard
curl -i http://dashboard.local/
curl -i http://dashboard.local/api/
curl -i http://dashboard.local/api/health
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                                                     READY   STATUS      RESTARTS   AGE
pod/dashboard-internal-dashboard-api-7dcf5b585f-6zn2j    1/1     Running     0          21m
pod/dashboard-internal-dashboard-redis-84bd66d95-cpdlx   1/1     Running     0          21m
pod/dashboard-internal-dashboard-smoke                   0/1     Completed   0          21m
pod/dashboard-internal-dashboard-web-664b5bf77b-hwpfx    1/1     Running     0          21m

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/dashboard-internal-dashboard-api     ClusterIP   10.43.124.42    <none>        8000/TCP   21m
service/dashboard-internal-dashboard-redis   ClusterIP   10.43.179.141   <none>        6379/TCP   21m
service/dashboard-internal-dashboard-web     ClusterIP   10.43.15.137    <none>        80/TCP     21m

NAME                                                     CLASS     HOSTS             ADDRESS      PORTS   AGE
ingress.networking.k8s.io/dashboard-internal-dashboard   traefik   dashboard.local   172.18.0.2   80      21m

NAME                                           ENDPOINTS         AGE
endpoints/dashboard-internal-dashboard-api     10.42.0.10:8000   21m
endpoints/dashboard-internal-dashboard-redis   10.42.0.9:6379    21m
endpoints/dashboard-internal-dashboard-web     10.42.0.11:80     21m

NAME                                                                 POD-SELECTOR                                                                                                       AGE
networkpolicy.networking.k8s.io/dashboard-internal-dashboard-api     app.kubernetes.io/component=api,app.kubernetes.io/instance=dashboard,app.kubernetes.io/name=internal-dashboard     21m
networkpolicy.networking.k8s.io/dashboard-internal-dashboard-redis   app.kubernetes.io/component=redis,app.kubernetes.io/instance=dashboard,app.kubernetes.io/name=internal-dashboard   21m
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 277
Content-Type: text/html; charset=utf-8
Date: Thu, 19 Nov 2026 12:48:16 GMT
Etag: "dmz6q6g0lf6a-7p"
Last-Modified: Thu, 19 Nov 2026 12:26:52 GMT
Server: Caddy
Vary: Accept-Encoding

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Internal Dashboard</title>
</head>
<body>
  <h1>Internal Dashboard</h1>
  <p>Static frontend served by Caddy.</p>
</body>
</html>
HTTP/1.1 200 OK
Content-Length: 46
Content-Type: application/json
Date: Thu, 19 Nov 2026 12:48:17 GMT
Server: gunicorn

{"cache":"ok","env":"prod","message":"Hello"}
HTTP/1.1 200 OK
Content-Length: 16
Content-Type: application/json
Date: Thu, 19 Nov 2026 12:48:17 GMT
Server: gunicorn

{"status":"OK"}

```


# Internal Dashboard

Запустити систему в Kubernetes, знайти проблеми, виправити їх і довести, що стек стабільно відповідає на три публічні адреси.

Стек: Helm-чарт `charts/internal-dashboard`, API (Flask/Gunicorn), статика (Caddy), Redis, Ingress через Traefik.

## Запуск

Потрібні `docker`, `kubectl`, `helm` і локальний кластер з Traefik. Нижче - `k3d` (k3s уже містить Traefik, ingress class `traefik`).

```bash
k3d cluster create dashboard --port "80:80@loadbalancer" --port "443:443@loadbalancer"

docker build -t internal-dashboard-api:local .
docker build -t internal-dashboard-frontend:local ./frontend
k3d image import internal-dashboard-api:local -c dashboard
k3d image import internal-dashboard-frontend:local -c dashboard

helm upgrade --install dashboard ./charts/internal-dashboard \
  -n dashboard --create-namespace --wait --timeout 5m
```

Додати в `/etc/hosts`:

```text
127.0.0.1 dashboard.local
```

Імена образів і теги мають збігатися з `charts/internal-dashboard/values.yaml`.

## Очікуваний результат

- `http://dashboard.local/` → HTML-сторінка (`Internal Dashboard`)
- `http://dashboard.local/api/` → `200` і JSON `{"message":"Hello","env":"prod","cache":"ok"}`
- `http://dashboard.local/api/health` → `200` і `{"status":"OK"}`
