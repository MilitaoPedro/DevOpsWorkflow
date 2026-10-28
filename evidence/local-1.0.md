### 1. Build local da imagem (docker build -t minha-aplicacao:1.0 .)
```
$ docker build -t minha-aplicacao:1.0 .
Successfully built / naming to docker.io/library/minha-aplicacao:1.0
```

### 2. Imagem criada
```
$ docker images minha-aplicacao:1.0
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
minha-aplicacao:1.0   4df5825aebab        138MB             0B   U    
```

### 3. Execucao do container
```
$ docker run -d --name minha-app -p 8080:8080 minha-aplicacao:1.0
minha-app | Up 14 seconds | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

### 4. Logs do container
```
$ docker logs minha-app
Aplicacao ouvindo na porta 8080
```

### 5. Teste do endpoint
```
$ curl http://localhost:8080/hello
Hello World
```
