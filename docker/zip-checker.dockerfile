FROM alpine:latest

RUN apk add --no-cache zip

ARG ZIP_PATH

COPY ${ZIP_PATH} /tmp/sample.zip

WORKDIR /tmp

CMD zip -T sample.zip
