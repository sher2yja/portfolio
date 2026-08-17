FROM maven:3.8.8-eclipse-temurin-8 AS builder
WORKDIR /app
COPY .mvn/ .mvn/
COPY pom.xml .
RUN rm -rf /root/.m2/repository
RUN mvn dependency:resolve dependency:resolve-plugins
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:8-jre-alpine
WORKDIR /app
RUN apk add --no-cache bash
COPY --from=builder /app/target/*.jar ./app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh
CMD ["./wait-for-it.sh", "-t", "40", "db:5432", "--", "java", "-jar", "./app.jar"]