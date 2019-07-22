FROM python:3.7.4-alpine3.9


RUN apk update
RUN pip install Flask

COPY hello_world.py ./

CMD python hello_world.py

EXPOSE 8000