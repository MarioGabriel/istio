FROM python:3.5-alpine3.9

RUN apk update

COPY index.html ./

CMD python http.server

EXPOSE 8000