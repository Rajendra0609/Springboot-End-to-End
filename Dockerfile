FROM openjdk:8-jdk-alpine

ARG artifact=target/springboot-0.0.1-SNAPSHOT.jar

WORKDIR /opt/app

COPY ${artifact} app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
