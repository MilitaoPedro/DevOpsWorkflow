# Evidencias - execucao final das imagens do registry (1.0 e 2.0)

Valida que as duas imagens publicadas pela pipeline podem ser baixadas do
registry, executadas e respondem corretamente pelo endpoint.

## Versao 1.0

```
$ docker run -d --name registry-app -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:1.0
registry-app | Up 3 seconds | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

$ curl http://localhost:8080/hello
Hello World
```

## Versao 2.0

```
$ docker run -d --name registry-app -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:2.0
registry-app | Up 3 seconds | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

$ curl http://localhost:8080/hello
Hello World 2
```

