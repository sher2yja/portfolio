#!/bin/bash
# Применение всех манифестов с замером времени переразвёртывания.
#
# Написан для пункта задания про сравнение стратегий Recreate и RollingUpdate:
# сам apply возвращается мгновенно, поэтому реальное время даёт не он, а
# ожидание завершения раскатки каждого Deployment через kubectl rollout status.
#
# Цикл идёт по всем Deployment в namespace, а не по списку имён: добавление
# нового сервиса в манифесты не требует правки скрипта.
#
# Запускать из корня проекта — путь ./manifests/ относительный.

start_time=$SECONDS

echo "1. Обновляем все конфиги"

kubectl apply -f ./manifests/

for deploy in $(kubectl get deployments -n basic-kuber -o name); do
    kubectl rollout status "$deploy" -n basic-kuber
done

end_time=$SECONDS
elapsed=$(( end_time - start_time ))

echo "2. Обновление завершено"
echo "-------------------------------------------"
echo "Полное время обновления составило: $elapsed секунд."
echo "-------------------------------------------"