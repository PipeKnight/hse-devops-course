FROM tiangolo/uwsgi-nginx:python3.7
COPY ./ /work
WORKDIR /work
RUN apk update
RUN apk add cmake make g++
RUN pip3 install flask
RUN cmake ./
RUN make
RUN adduser -S techproguser -s /bin/sh
CMD ["python3", "/work/app.py", "--port", "5000", "--host", "0.0.0.0"]
