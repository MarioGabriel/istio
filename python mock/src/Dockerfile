FROM python:3.5-alpine3.9

RUN apk update
RUN pip install Flask

CMD virtualenv flask
CMD source bin/activate

COPY hello-world.py ./flask/

CMD python flask/hello-world.py
EXPOSE 5000
