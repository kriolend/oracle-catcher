> **Для AI-ассистентов:** Перед началом работы обязательно прочитай файл `.ai/session_state.md`. 
> Главное правило: ИИ запрещено создавать файлы или выполнять bash-команды. Пользователь пишет код только сам.


# Enterprise DevOps Infrastructure Lab

Этот проект — практическая реализация инфраструктуры (от локального сетапа до облачного K3s) с соблюдением стандартов немецкого Enterprise рынка.

## 🌟 Ключевые архитектурные решения (German Market Standards)
1. **Conventional Commits**: Строгая стандартизация коммитов (feat, fix, chore) для автоматической генерации changelog-ов.
2. **Pre-commit Automation**: Использование `pre-commit` хуков (форматирование Terraform, проверка YAML, поиск утекших секретов) перед каждым коммитом, чтобы гарантировать чистоту кода.
3. **Dual CI/CD Strategy (GitHub + GitLab)**: 
   * Проект хостится на **GitHub** для максимальной видимости рекрутерам.
   * CI/CD пайплайны реализованы **и в GitHub Actions, и в GitLab CI**, чтобы продемонстрировать готовность к суровым Enterprise-реалиям (где GitLab Self-Hosted — абсолютный стандарт).
4. **Zero-Budget Cloud**: Использование бесплатных ресурсов GCP (e2-micro) с жесткой оптимизацией памяти (SWAP) и автоматическим скалированием на Oracle ARM (когда будет пойман инстанс).

## 🏗️ Terraform Modules

Reusable modules under `terraform/modules/`:

| Module | Purpose |
|--------|---------|
| `k3s_network` | VPC, subnet, firewall rules for K3s cluster |
| `k3s_node`   | Compute instance with K3s server/agent setup |

## Этапы развития (Phases)
### Phase 1: Local Foundation & IaC
* Git, Taskfile, Pre-commit hooks
* Modular Terraform (`terraform/modules/`) для провижининга GCP e2-micro
* Safe mode: `terraform/vyacheslav` использует существующую сеть (пропускает создание, если сеть уже есть)

### Phase 2: Configuration & Optimization
* Ansible для базовой настройки (SWAP, security)
* Деплой Oracle Catcher в фон

### Phase 3: Local Kubernetes (Sandbox)
* Minikube, Helm, ArgoCD (GitOps) локально

### Phase 4: Lightweight Cloud Cluster (K3s)
* K3s (Diet Mode - без Traefik и метрик) через Ansible

### Phase 5: Enterprise Stack
* ArgoCD (Cloud), Prometheus Agent, Loki + Promtail
