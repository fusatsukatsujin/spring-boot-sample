# ビルドステージ
FROM gradle:8.5-jdk17 AS build

WORKDIR /app
COPY build.gradle settings.gradle ./
# 依存関係を先にダウンロード
RUN gradle dependencies --no-daemon

COPY . .
RUN gradle build --no-daemon

# 実行ステージ
FROM eclipse-temurin:17-jre

WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"] 