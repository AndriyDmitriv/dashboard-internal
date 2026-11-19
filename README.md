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

Перевірка з хоста, через Ingress. `kubectl port-forward` не замінює цей результат.

## Умови зарахування

Тестове - фільтр перед технічною співбесідою. Частково робочий стек не проходить далі.

Обов'язково все з цього списку:

1. Чистий кластер піднімається однією командою `helm upgrade --install dashboard ./charts/internal-dashboard -n dashboard --create-namespace --wait` без ручних `kubectl edit` / `kubectl patch` після деплою.
2. Усі сервісні Pod (`api`, `web`, `redis`) у namespace `dashboard` у стані `Running` і `Ready`. Через 3 хвилини після `--wait` у них `0` рестартів.
3. Усі три URL вище відповідають `200` і очікуваним тілом.
4. `helm test dashboard -n dashboard` завершується успішно, включно з паралельним навантаженням на `/api/`, без таймаутів і без рестартів Pod.
5. Зміна конфігурації в `values.yaml` (наприклад, `web.caddyRoot` або ключів ConfigMap) і повторний `helm upgrade` самі перезапускають Pod, який цю конфігурацію читає. Ручний `kubectl rollout restart` або видалення Pod не зараховується.
6. CI на push збирає обидва образи і валідує чарт: `helm lint` та `helm template`.

Завдання не зараховане, якщо проблему прибрали разом із механізмом:

- видалені або вимкнені `livenessProbe` / `readinessProbe`;
- видалена `NetworkPolicy`;
- видалені `resources.requests` або `resources.limits`;
- `APP_ENV` або `REDIS_URL` захардкожені в Dockerfile чи в команді контейнера замість ConfigMap/Secret;
- видалений або змінений `readOnlyRootFilesystem: true` у `securityContext` контейнера `api`;
- змінені файли в `app/` або `frontend/` (дозволено змінювати `Dockerfile`, `charts/` і `.github/`);
- видалені або послаблені `LimitRange` / `ResourceQuota`;
- зовнішній доступ зроблений через `NodePort`, `hostNetwork` або `port-forward` замість Ingress.

## Що здати

1. Посилання на репозиторій з виправленнями або архів репозиторія.
2. `REPORT.md`: список проблем у форматі симптом → причина → fix.
3. Реальний вивід після чистого деплою:

```bash
kubectl get pods,svc,ingress,endpoints,networkpolicy -n dashboard
curl -i http://dashboard.local/
curl -i http://dashboard.local/api/
curl -i http://dashboard.local/api/health
helm test dashboard -n dashboard
```

4. Коротко: що змінилось у CI.

Використання ChatGPT, Claude Code, Cursor, Gemini та інших AI-інструментів дозволено. На технічній співбесіді треба пояснити власні виправлення. Розбіжність між `REPORT.md` і `git diff` (описані зміни, яких немає в коді) означає, що завдання не зараховане.
