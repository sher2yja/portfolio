# Изоляция staging и production namespace'ами

Staging и production развёрнуты отдельными Helm-релизами в `do14-helm` и `do14-production`. У каждого собственные Secret, PostgreSQL и Redis PVC; это предотвращает смешение данных и позволяет обновлять staging автоматически, а production — только вручную через workflow. Изоляция namespace не заменяет отдельные кластеры: обе среды делят одну локальную VM и её отказ.
