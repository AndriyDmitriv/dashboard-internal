# infra

AKS + Argo CD + HAProxy + cert-manager + ACR + WireGuard. Terraform + Helm.


## 1. State

```bash
az group create -n rg-tfstates -l swedencentral
az storage account create -n <sa-name> -g rg-tfstates -l swedencentral --sku Standard_LRS
az storage container create -n tfstate --account-name <sa-name> --auth-mode login
cp backend.hcl.example backend.hcl   # вписати <sa-name>
```

## 2. Конфіг

```bash
cp terraform.tfvars.example terraform.tfvars
```

Змінити:

- `subscription_id`: `az account show --query id -o tsv`
- `location`: регіон
- `name_prefix`: префікс імен
- `system_node_vm_size`: розмір нод під квоту
- `app_host`: домен застосунку
- `acme_email`: пошта для Let's Encrypt
- `cluster_issuer`: спершу `letsencrypt-staging`, потім `letsencrypt-prod`
- `app_repo_url`: git-репо з чартом
- `app_target_revision`: гілка
- `github_repository`: `owner/repo` для CI
- `github_oidc_repo`: `owner@id/repo@id` (з помилки azure/login)
- `wireguard_peers`: імена VPN-клієнтів

## 3. Запуск

```bash
terraform init -backend-config=backend.hcl
terraform apply
```

## 4. Після apply

- DNS: A-запис `app_host` → `terraform output ingress_public_ip`
- GitHub → Settings → Secrets → Actions: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME` з `terraform output github_actions_variables`
- push у гілку → CI збирає образи, міняє тег у `charts/internal-dashboard/values-aks.yaml`, Argo CD деплоїть

## VPN

```bash
$(terraform output -raw aks_get_credentials)
kubectl -n wireguard exec deploy/wireguard -c wireguard -- cat /config/peer_admin/peer_admin.conf | cat > admin.conf
nmcli connection import type wireguard file admin.conf
```

Argo CD (через VPN): `terraform output argocd_url_via_vpn`, пароль: `terraform output -raw argocd_admin_password_command | sh`

## Видалення

```bash
terraform destroy
```

Диск з ключами WireGuard лишається, видалити вручну в `MC_*` resource group.
