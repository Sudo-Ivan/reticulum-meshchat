FROM node:23-alpine AS build-frontend

WORKDIR /src

COPY --chown=node:node *.json .
COPY --chown=node:node *.js .
COPY --chown=node:node src/frontend ./src/frontend

USER root
RUN chown -R node:node /src
USER node
RUN npm install --omit=dev && \
  npm run build-frontend

FROM python:3.13-alpine

WORKDIR /app

RUN apk add --no-cache \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev

RUN mkdir -p /config/.reticulum /config/.meshchat && \
    chown -R 1000:1000 /config

COPY --chown=1000:1000 ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /app/public
COPY --from=build-frontend --chown=1000:1000 /src/public/ /app/public/

COPY --chown=1000:1000 *.py .
COPY --chown=1000:1000 src/__init__.py ./src/__init__.py
COPY --chown=1000:1000 src/backend ./src/backend
COPY --chown=1000:1000 *.json .

USER 1000
ENTRYPOINT ["python"]
CMD ["meshchat.py", "--host=0.0.0.0", "--reticulum-config-dir=/config/.reticulum", "--storage-dir=/config/.meshchat", "--headless"]
