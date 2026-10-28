### 1. Build local da imagem 2.0
```
$ docker build -t minha-aplicacao:2.0 .
naming to docker.io/library/minha-aplicacao:2.0
```

### 2. Execucao do container
```
$ docker run -d --name minha-app -p 8080:8080 minha-aplicacao:2.0
minha-app | Up 31 seconds | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

### 3. Logs do container
```
$ docker logs minha-app
Aplicacao ouvindo na porta 8080
```

### 4. Teste do endpoint
```
$ curl http://localhost:8080/hello
Hello World 2
```
