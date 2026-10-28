# Evidencias - imagem 1.0 publicada pelo GitHub Actions

Pipeline: https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40615501744
Commit: a975c3e | Evento: push | Branch: main | Resultado: success

## 1. Download da imagem do registry
```
$ docker pull ghcr.io/militaopedro/devopsworkflow:1.0
Digest: sha256:bc4a85cca3c7264a44f71da15cf3133371e426c50d23fb2b8cb10bdb5218e141
Status: Downloaded newer image for ghcr.io/militaopedro/devopsworkflow:1.0
```

## 2. Execucao do container baixado do registry
```
$ docker run -d --name registry-app -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:1.0
registry-app | Up 15 seconds | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

## 3. Teste do endpoint
```
$ curl http://localhost:8080/hello
Hello World
```
