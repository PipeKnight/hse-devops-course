FROM maven:3.8-jdk-8
RUN mkdir work
WORKDIR /work
COPY ./ /work
RUN ["mvn", "package", "-P", "init-base", "-DskipTests", "-Dmaven.wagon.httpconnectionManager.maxTotal=1"]
CMD ["/bin/bash", "launch_app.sh"]
