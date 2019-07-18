FROM python:3.5-alpine3.9

RUN apk update
RUN pip install Flask

<<<<<<< HEAD
COPY hello-world.py ./
CMD python hello-world.py
=======
CMD virtualenv flask
CMD source bin/activate

COPY hello-world.py ./flask/

CMD python flask/hello-world.py
EXPOSE 5000
>>>>>>> d30e12735c47a682eef2f229ecc601921ebbc55f
