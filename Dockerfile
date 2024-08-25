# Stage 1: Build
FROM openjdk:8-jdk-alpine as build

ARG artifact=target/springboot-0.0.1-SNAPSHOT.jar

WORKDIR /opt/app

COPY ${artifact} app.jar

# Stage 2: Runtime
FROM openjdk:8-jdk-alpine

WORKDIR /opt/app

COPY --from=build /opt/app/app.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
