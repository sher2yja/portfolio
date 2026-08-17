FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY .mvn/ .mvn/
COPY pom.xml .
RUN mvn -B -Dmaven.repo.local=/root/.m2/repository --no-transfer-progress dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
RUN apk add --no-cache bash
COPY --from=builder /app/target/*.jar ./app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh
CMD ["./wait-for-it.sh", "-t", "40", "db:5432", "--",\
     "./wait-for-it.sh", "-t", "40", "rabbitmq:5672", "--",\
     "java", "-jar", "./app.jar"]