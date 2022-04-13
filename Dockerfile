FROM maven:3.8.4-openjdk-11-slim

RUN mkdir -p /my-project

WORKDIR /my-project

ADD ./my-project  /my-project/

RUN mvn clean install

EXPOSE 8080

ENTRYPOINT java -jar -Xdebug /my-project/targe/my-project-1.0.0-SNAPSHOT.jar