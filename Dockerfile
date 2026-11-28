# Bileklik test portalı: portal sunucusu + uygulamanın web sürümü.
# Bu dosya portal-deploy dalında, CI'ın derlediği dosyalarla birlikte durur
# (server: derlenmiş portal, site/: açılış sayfası ve uygulama). Burada
# derleme yapılmaz; Render gibi küçük makinelerde hızlı açılır.
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY server /app/server
COPY site /app/site
RUN chmod +x /app/server
ENV PORTAL_DEMO=1 PORTAL_SITE=/app/site PORTAL_HTTPS=1
EXPOSE 8080
CMD ["/app/server"]
