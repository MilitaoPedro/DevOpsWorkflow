# Evidencias - imagem 2.0 publicada pelo GitHub Actions

Pipeline: https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40616143584
Commit: 93836cc | Evento: push | Branch: main | Resultado: success

## 1. Download da imagem do registry
```
$ docker pull ghcr.io/militaopedro/devopsworkflow:2.0
Digest: sha256:bb854bfa81d3f1354df9ee7117c844020ad89f4086118d479bddfc8e120bcd11
Status: Downloaded newer image for ghcr.io/militaopedro/devopsworkflow:2.0
```

## 2. Execucao do container baixado do registry
```
$ docker run -d --name registry-app -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:2.0
```

## 3. Teste do endpoint
```
$ curl http://localhost:8080/hello
Hello World 2
```

## 4. Tags disponiveis no registry
```
$ docker buildx imagetools inspect ghcr.io/militaopedro/devopsworkflow:1.0
Name:      ghcr.io/militaopedro/devopsworkflow:1.0
MediaType: application/vnd.docker.distribution.manifest.v2+json
Digest:    sha256:bc4a85cca3c7264a44f71da15cf3133371e426c50d23fb2b8cb10bdb5218e141

$ docker buildx imagetools inspect ghcr.io/militaopedro/devopsworkflow:2.0
Name:      ghcr.io/militaopedro/devopsworkflow:2.0
MediaType: application/vnd.docker.distribution.manifest.v2+json
Digest:    sha256:bb854bfa81d3f1354df9ee7117c844020ad89f4086118d479bddfc8e120bcd11
```
