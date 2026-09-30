#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for script in ci/*.sh tools/*.sh tests/*.sh; do bash -n "$script"; done
shellcheck ci/*.sh tools/*.sh tests/*.sh
node --test tests/check-health.test.mjs
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
for environment in staging production candidate; do
  args=(--set existingSecret=n8n-secrets)
  if [[ "$environment" == candidate ]]; then
    args+=(-f chart/values-staging.yaml --set service.type=ClusterIP)
  else
    args+=(-f "chart/values-$environment.yaml")
  fi
  helm lint chart "${args[@]}"
  helm template do14 chart "${args[@]}" > "$temporary/$environment.yaml"
done
python3 - "$temporary" <<'PY'
import pathlib, sys, yaml
for environment in ('staging', 'production', 'candidate'):
    objects=list(yaml.safe_load_all((pathlib.Path(sys.argv[1])/f'{environment}.yaml').read_text()))
    workloads=[x for x in objects if x['kind'] in ('Deployment','StatefulSet')]
    assert len(workloads)==5
    assert sum(x['spec']['replicas'] for x in workloads)==5
    worker=next(x for x in workloads if x['metadata']['name']=='do14-worker')
    assert len(worker['spec']['template']['spec']['containers'])==2
    services={x['metadata']['name']:x for x in objects if x['kind']=='Service'}
    for role,offset in [('main',0),('webhook',1)]:
        service=services[f'do14-{role}']['spec']
        if environment=='candidate':
            assert service['type']=='ClusterIP' and 'nodePort' not in service['ports'][0]
        else:
            assert service['type']=='NodePort'
            assert service['ports'][0]['nodePort']==({'staging':30678,'production':31678}[environment]+offset)
    assert all('cluster-summary' not in x['metadata']['name'] for x in objects)
print('Chart invariants: staging, production, candidate OK')
PY
# Invalid arguments and absent credentials must fail before Kubernetes mutations.
if bash ci/deploy.sh invalid >/dev/null 2>&1; then exit 1; fi
if env -u REGISTRY -u IMAGE_TAG bash ci/build.sh >/dev/null 2>&1; then exit 1; fi
if HELM_RELEASE=do14 WEBHOOK_BASE_URL=http://127.0.0.1:1 bash ci/test.sh http://127.0.0.1:1 >/dev/null 2>&1; then exit 1; fi
echo 'Local checks passed'
