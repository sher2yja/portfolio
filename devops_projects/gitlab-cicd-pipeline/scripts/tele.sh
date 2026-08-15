#!/bin/bash

# Уведомление о статусе пайплайна в Telegram.
# Вызывается из after_script каждой стадии .gitlab-ci.yml.
#
# Токен и chat_id берутся из переменных GitLab CI/CD
# (Settings -> CI/CD -> Variables), а не хранятся в репозитории:
#   TELEGRAM_BOT_TOKEN - токен бота от @BotFather, тип Masked
#   TELEGRAM_USER_ID   - chat_id получателя
#
# Код возврата скрипта виден в логе: ненулевой GitLab покажет как
# "after_script failed", но саму задачу не уронит. Поэтому отсутствие
# переменных — не ошибка, а пропуск уведомления с выходом 0: конвейер
# не должен зависеть от доступности мессенджера.
#
# Статус берётся из CI_JOB_STATUS, который GitLab заполняет только
# в after_script. В обычном script этой переменной ещё нет — знать
# результат задачи изнутри неё самой невозможно.

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_USER_ID" ]]; then
    echo "TELEGRAM_BOT_TOKEN и TELEGRAM_USER_ID не заданы — уведомление пропущено"
    exit 0
fi

URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"

if [[ "$CI_JOB_STATUS" == "failed" ]]; then
    STATUS_ICON="❌"
    STATUS_TEXT="Failed"
else
    STATUS_ICON="✅"
    STATUS_TEXT="Success"
fi

DEPLOY_OR="CI"
if [[ "$CI_JOB_STAGE" = "deploy" ]]; then
    DEPLOY_OR="CD"
fi

TEXT="$STATUS_ICON $STATUS_TEXT $DEPLOY_OR%0A%0AProject: $CI_PROJECT_NAME%0AURL: $CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID%0ABranch: $CI_COMMIT_REF_SLUG%0AStage: $CI_JOB_STAGE%0ACommit: $CI_COMMIT_MESSAGE"

curl -s --max-time 20 \
  -d "chat_id=$TELEGRAM_USER_ID&disable_web_page_preview=1&text=$TEXT" \
  "$URL"
