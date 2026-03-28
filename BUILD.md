# Como buildar a imagem da API

##  Build da imagem

```powershell
cd C:\laragon\www\docker-infra
docker build -t api_mvc:latest .
```

##  Verificar imagem criada

```powershell
docker images | findstr api_mvc
```

##  Rebuild (quando atualizar Dockerfile)

```powershell
docker build --no-cache -t api_mvc:latest .
```

##  O que está na imagem?

-  PHP 8.1 + Nginx + PHP-FPM
-  Extensões: pdo_mysql, pdo_pgsql, mysqli, pgsql, gd, soap, zip, mbstring
-  Composer instalado
-  Nginx configurado para servir a API
-  Upload até 100MB
-  Memory limit 256MB

##  Rebuild obrigatório após adicionar driver

Se a API já estava rodando antes dessa alteração, faça rebuild da imagem para o driver PostgreSQL entrar de fato no container:

```powershell
cd C:\laragon\www\docker-infra
docker build --no-cache -t api_mvc:latest .
```

##  Usar em projetos

Depois de buildar, qualquer projeto pode usar:

```yaml
services:
  api:
    image: api_mvc:latest  #  Usa a imagem buildada
    volumes:
      - ./api:/var/www/html
    ports:
      - "8089:80"
```
