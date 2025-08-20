# Etapa 1: Construcción
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

# Instalar dependencias
RUN flutter pub get

# Compilar en modo web release
RUN flutter build web --release

# Etapa 2: Servidor web con Nginx
FROM nginx:alpine

# Copiar artefactos compilados al servidor
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
