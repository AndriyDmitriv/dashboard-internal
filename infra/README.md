# AKS + Argo CD + WireGuard

Terraform-стек для Azure: VNet і AKS, Argo CD у кластері без публічного доступу та WireGuard VPN, через який до нього ходять. Усе створюється одним `terraform apply`, а компоненти всередині кластера ставляться Helm-чартами через `helm_release`.

```
RG → VNet → AKS → static Public IP → Argo CD (ClusterIP) + WireGuard (UDP LoadBalancer)
```

Вимоги, архітектура й критерії приймання: [TZ.md](./TZ.md).

## Структура

```
.
├── versions.tf          # провайдери (azurerm, helm) і backend
├── main.tf              # склеювання модулів
├── variables.tf / outputs.tf
├── terraform.tfvars.example
├── backend.hcl.example
└── modules/
    ├── rg/  vnet/  aks/
    ├── argocd/          # argo-helm/argo-cd
    └── wireguard/       # локальний чарт linuxserver/wireguard
```

## Що потрібно

- Terraform >= 1.6
- Azure CLI після `az login` (або змінні `ARM_*` сервіс-принципала)
- Зареєстровані провайдери ресурсів: `Microsoft.ContainerService`, `Microsoft.Network`, `Microsoft.Compute`, `Microsoft.Storage`
- Квота щонайменше 6 vCPU на сімейство обраного розміру VM у регіоні
- `kubectl` і клієнт WireGuard, щоб користуватися результатом

## Запуск

```bash
cp terraform.tfvars.example terraform.tfvars   # subscription_id, name_prefix, peers
cp backend.hcl.example backend.hcl             # де зберігати remote state

terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

Якщо хочеш швидко перевірити без remote state, тимчасово прибери `backend "azurerm" {}` з `versions.tf` і запусти `terraform init`. Стейт буде локальним. Такі зміни не коміть: у стейті є kubeconfig кластера.

## Підключення

```bash
# kubeconfig
$(terraform output -raw aks_get_credentials)

# конфіг VPN-клієнта: імпортуй admin.conf у застосунок WireGuard
terraform output -json wireguard_peer_config_commands | jq -r '.admin' | sh > admin.conf

# з увімкненим VPN
terraform output argocd_url_via_vpn                   # http://argo-cd-argocd-server.argocd.svc.cluster.local
terraform output -raw argocd_admin_password_command | sh
```

## Основні змінні

| Змінна | Типово | Опис |
|---|---|---|
| `subscription_id` | — | ID підписки Azure |
| `name_prefix` | — | Префікс імен ресурсів (3–12 символів, малі літери та цифри) |
| `location` | `westeurope` | Регіон |
| `kubernetes_version` | `null` | `null` означає останню GA-версію в регіоні. Для довгоживучого кластера зафіксуй версію |
| `system_node_vm_size` | `Standard_D2s_v7` | Розмір нод |
| `system_node_min_count` / `system_node_max_count` | `1` / `3` | Межі autoscaler |
| `aks_sku_tier` | `Free` | `Free` або `Standard` |
| `argocd_chart_version` | `10.18.2` | Версія чарту `argo-cd` |
| `wireguard_peers` | `["admin"]` | Імена VPN-клієнтів (тільки літери й цифри) |
| `wireguard_source_ranges` | `[]` | З яких CIDR пускати на UDP-порт (порожньо — з будь-яких) |
| `vnet_address_space`, `aks_subnet_prefix`, `service_cidr`, `dns_service_ip`, `wireguard_internal_subnet` | див. `variables.tf` | Мережі не повинні перетинатися |

## Застосунок: HAProxy + cert-manager + Argo CD Application

Стек також ставить:

- **HAProxy Ingress** (`modules/haproxy-ingress`): публічний LoadBalancer зі статичним IP, IngressClass `haproxy` за замовчуванням;
- **cert-manager** (`modules/cert-manager`): ClusterIssuer `letsencrypt-staging` і `letsencrypt-prod`, HTTP-01 через HAProxy;
- **ACR** (`modules/acr`): AKS отримує `AcrPull`; GitHub Actions пушить образи через OIDC (identity з `AcrPush`);
- **Argo CD Application** `internal-dashboard` (`modules/argocd-apps`): чарт `charts/internal-dashboard` з `app_repo_url`, образи з ACR, Ingress на `app_host` з TLS.

Порядок першого запуску:

1. У `terraform.tfvars` задай `app_host`, `acme_email`, `app_repo_url`, `github_repository` (див. `terraform.tfvars.example`).
2. `terraform apply`.
3. DNS: A-запис `app_host` на `terraform output ingress_public_ip`.
4. GitHub → Settings → Secrets and variables → Actions → **Variables**: додай чотири значення з `terraform output github_actions_variables`.
5. Push у гілку `app_target_revision` (або **Run workflow** для `Build, push, bump tags`): образи потраплять в ACR, а тег — у `values-aks.yaml`.
6. Argo CD сам синхронізує застосунок; cert-manager видасть сертифікат, щойно DNS почне резолвитися.

Поки образів в ACR немає, поди застосунку будуть в `ImagePullBackOff`. Це очікувано.

### CI/CD: як оновлюються образи

`.github/workflows/push-images.yml` на кожен push у гілку `app_target_revision`:

1. збирає обидва образи з тегом `<sha коміту>` і пушить їх в ACR (вхід через OIDC, без секретів);
2. записує цей тег у `charts/internal-dashboard/values-aks.yaml`;
3. комітить зміну назад у ту саму гілку (`bump <sha>`).

Argo CD бачить новий коміт і розгортає нову версію. Відкат робиться через `git revert` коміту `bump ...`.

Реєстр і `pullPolicy` задає Terraform (inline values в Application), а теги задає CI через git-файл. Вони не перетинаються, тож `terraform apply` не відкочує тег, виставлений CI.

## Видалення

```bash
terraform destroy
```

PVC з ключами WireGuard має `helm.sh/resource-policy: keep`, тож Azure-диск переживе `destroy`. Якщо ключі більше не потрібні, видали його вручну (у node resource group `MC_rg-<prefix>_aks-<prefix>_<region>`). Інакше він далі тарифікується.
