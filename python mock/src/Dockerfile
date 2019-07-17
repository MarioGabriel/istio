FROM python:3.8.0b2-alpine3.10

RUN apk update
RUN pip install Flask

COPY hello-world.py ./
CMD python hello-world.py
