# Права локального GitHub Actions runner

Runner вынесен в отдельную VM без общей папки с основным ПК. Его Kubernetes ServiceAccount ограничен двумя namespace приложения и типами ресурсов, нужными Helm-чарту; доступа к созданию Namespace и Secret в `kube-system` нет. Helm хранит историю релизов в Secret, поэтому runner имеет права на Secret внутри разрешённых namespace: это остаточный риск, ради которого нельзя запускать на нём произвольные workflow из недоверенных изменений.
