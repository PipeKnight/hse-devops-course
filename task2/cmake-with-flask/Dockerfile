FROM python:3.8-alpine
COPY ./ /work
WORKDIR /work
RUN apk update
RUN apk add cmake make g++
RUN pip3 install flask
RUN cmake ./
RUN make
RUN adduser -S techproguser -s /bin/sh
USER techproguser
CMD ["python3", "/work/app.py", "--port", "5000", "--host", "0.0.0.0"]
