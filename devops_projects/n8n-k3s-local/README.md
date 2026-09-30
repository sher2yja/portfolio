# n8n в k3s

Рабочая часть учебного проекта перенесена в **[src/](src/README.md)**: четыре собственных образа, Helm, Ansible/Vagrant, CI-скрипты, Newman и настройки GitLab Runner.

Версии: n8n/task-runner 2.40.7, k3s v1.35.8+k3s1; гостевая Ubuntu 24.04. Инструкция конечного хоста описывает Ubuntu 22.04. Проверки и незакрытые условия — в [src/report.md](src/report.md).

GitHub Actions обслуживает кластер портфолио. GitLab будет обслуживать отдельный кластер Максима; проверка школьного GitLab С1 пока открыта.

## Дополнительные материалы

- [История портфолио](docs/portfolio-history.md) и [прежний отчёт](main_report.md) сохраняют результаты прежних прогонов.
- `runner/` — прежняя VM GitHub runner; `src/runner/` — GitLab Runner.
- `monitoring/`, `scripts/`, `systemd/` — мониторинг и резервирование; они не входят в передаваемый `src/`.
- `experiments/`, `k8s/base/`, `workflows/` — дополнительные примеры.
- [Документ разделения работ](docs/remaining-work-and-split.md) — исходный материал для согласованного плана.
