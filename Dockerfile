FROM public.ecr.aws/docker/library/bash:5.2.37-alpine3.21
RUN apk add --no-cache openssl curl
WORKDIR /app
COPY argo_external_ssl_check.sh /app/
ENTRYPOINT ["bash", "/app/argo_external_ssl_check.sh", "/app/certificate.yaml"]
