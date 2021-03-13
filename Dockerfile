FROM alpine:latest
RUN apk add --no-cache openssh
RUN mkdir /root/.ssh/
