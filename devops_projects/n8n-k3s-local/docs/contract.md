# Контракт приложения и платформы

Актуальный рабочий каталог: `src/`. Исторические результаты прежнего GitHub цикла находятся в `main_report.md`; новый цикл требует отдельного подтверждения.

| Параметр | Контракт |
|---|---|
| Версия | `src/chart/Chart.yaml: appVersion`, n8n/task-runner 2.40.7 |
| Образы | `$REGISTRY/{main,webhook,worker,runner}:$IMAGE_TAG`, один проверенный тег |
| Release | `do14`, staging `do14-helm`, production `do14-production`; имена существующих PVC сохранены |
| Доступ | staging NodePort 30678/30679, production 31678/31679 |
| Секреты | внешний `n8n-secrets`, три постоянных значения; повторный deploy запрещает неявную смену |
| Registry | push credentials для build; постоянный read-only deploy token для pull-secret |
| Candidate | уникальный `do14-test-*` в staging, ClusterIP, отдельная БД/PVC/секреты, Newman и очистка |
| Кластеры | GitHub — портфолио; GitLab — отдельный кластер Максима |
| GitLab CI | Максим: feature build/test; ручной staging после test; ручной production после staging с тем же тегом |
| Завершение передачи | реальный С1 на школьном GitLab + воспроизведение Максимом на чистом Ubuntu 22.04 |

Подробные команды: [src/README.md](../src/README.md). Проверки: [src/report.md](../src/report.md). Backup/restore и мониторинг остаются дополнительными материалами вне передаваемого src.
