# CLAUDE.md

このファイルは、Claude Code / Cursor などの AI アシスタントがこのプロジェクトで作業する際のガイドです。

## プロジェクト概要

Spring Boot 3 のサンプルアプリに、Prometheus / Grafana / Loki による統合監視環境を組み合わせたプロジェクトです。ユーザー登録・一覧表示（DynamoDB）のシンプルな Web アプリを中心に、ローカル開発（Docker Compose）と AWS 本番展開（Terraform + ECS Fargate）の両方を扱います。

**ワークスペース構成**: リポジトリのルートは `spring-boot-demo/` です（親ディレクトリ `spring-boot-sample/` はワークスペース用のラッパー）。

## 技術スタック

| 領域 | 技術 |
|------|------|
| 言語・ランタイム | Java 17 |
| フレームワーク | Spring Boot 3.3.6 |
| ビルド | Gradle 8.5（`./gradlew`） |
| テンプレート | Thymeleaf |
| データベース | DynamoDB（ローカル: DynamoDB Local / 本番: AWS DynamoDB） |
| 監視 | Spring Actuator, Micrometer Prometheus, Loki, Promtail, Grafana |
| コンテナ | Docker, Docker Compose |
| インフラ | Terraform（AWS: ECR, ECS Fargate, DynamoDB, VPC） |
| リージョン | `ap-northeast-1`（固定） |

## ディレクトリ構成

```
spring-boot-demo/
├── src/main/java/com/example/demo/
│   ├── DemoApplication.java          # エントリポイント
│   ├── config/DynamoDBConfig.java    # DynamoDB クライアント設定
│   └── controller/
│       ├── HomeController.java       # ユーザー一覧・登録
│       └── UserForm.java             # フォーム DTO
├── src/main/resources/
│   ├── application.properties        # ローカル / デフォルト設定
│   ├── application-prod.properties   # 本番プロファイル
│   ├── logback-spring.xml            # ログ（STDOUT + CloudWatch）
│   └── templates/index.html          # Thymeleaf テンプレート
├── src/test/java/                    # JUnit 5 テスト
├── prometheus/                       # Prometheus スクレイプ設定
├── loki/                             # Loki 設定
├── promtail/                         # Promtail 設定
├── grafana/provisioning/             # Grafana データソース自動プロビジョニング
├── terraform/
│   ├── infrastructure/               # ECR, DynamoDB, VPC, セキュリティグループ
│   └── application/                  # ECS クラスター, タスク定義, サービス
├── docker-compose.yml
├── Dockerfile
└── build.gradle
```

## よく使うコマンド

```bash
# ローカル開発（全サービス起動）
docker-compose up -d

# アプリのみ再ビルド・再起動
docker-compose build app && docker-compose up -d app

# Gradle ビルド・テスト
./gradlew build
./gradlew test

# Actuator エンドポイント確認
curl http://localhost:8080/actuator/prometheus
curl http://localhost:8080/actuator/health

# サービスログ確認
docker-compose logs app
docker-compose logs promtail
```

### ローカルアクセス先

| サービス | URL | 備考 |
|----------|-----|------|
| アプリ | http://localhost:8080 | ユーザー登録・一覧 |
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | |
| Loki | http://localhost:3100 | |
| DynamoDB Admin | http://localhost:8001 | |

## アーキテクチャ上の重要ポイント

### DynamoDB

- テーブル名は **`Users`**（ハッシュキー: `id` / 文字列型）
- ローカル: `DYNAMODB_ENDPOINT=http://dynamodb-local:8000`（docker-compose が設定）
- `docker-compose` の `dynamodb-init` サービスがテーブルを自動作成する
- `DynamoDBConfig` は `amazon.dynamodb.endpoint` プロパティでエンドポイントを上書きする
- 本番: `SPRING_PROFILES_ACTIVE=prod` で `application-prod.properties` が有効になる

### 監視・ログ

- メトリクス: Spring Actuator `/actuator/prometheus` → Prometheus → Grafana
- ログ: アプリ標準出力 → Promtail（Docker ログ収集）→ Loki → Grafana
- Grafana のデータソースは `grafana/provisioning/datasources/` で自動設定される
- 本番ログは `logback-spring.xml` の `AWS_LOGS` appender で CloudWatch（`/ecs/spring-demo-app`）にも送信される

### Terraform デプロイ順序

1. `terraform/infrastructure/` を先に `terraform apply`（ECR, DynamoDB, VPC 等）
2. `terraform/application/` を次に `terraform apply`（ECS。infrastructure の tfstate を参照）
3. アプリイメージを ECR に push してから ECS サービスを更新する

**注意**: `terraform/**/terraform.tfstate` は `.gitignore` 対象。コミットしないこと。

## コーディング規約

- **パッケージ**: `com.example.demo` 配下に配置する
- **コントローラー**: `@Controller` + Thymeleaf（REST API ではない）
- **DynamoDB アクセス**: 現状は `DynamoDbClient` の低レベル API（`scan`, `putItem`）を直接使用。`DynamoDbEnhancedClient` の Bean は定義済みだが未使用
- **Lombok**: `build.gradle` に依存関係あり。必要に応じて `@Data` 等を使用可
- **設定値**: 環境依存の値は `application.properties` / 環境変数で管理し、ハードコードしない
- **エラーページ**: ローカルではスタックトレース表示あり（`server.error.include-stacktrace=always`）。本番プロファイルでは非表示

## 変更時の注意事項

- **依存関係を変更した場合**: `./gradlew build` のほか、`docker-compose build app` も必要
- **DynamoDB テーブルスキーマ変更**: `docker-compose.yml` の `dynamodb-init` と `terraform/infrastructure/main.tf` の両方を整合させる
- **Actuator エンドポイント追加**: `application.properties` の `management.endpoints.web.exposure.include` を更新する
- **Prometheus ターゲット**: `prometheus/prometheus.yml` の `targets` は Docker ネットワーク内の `app:8080` を指す
- **PostgreSQL 依存**: `build.gradle` に `postgresql` が含まれるが、現状アプリでは未使用（削除は影響確認後に）

## テスト

- フレームワーク: JUnit 5（`@SpringBootTest`）
- 現状はコンテキストロードテストのみ（`DemoApplicationTests`）
- テスト実行: `./gradlew test`
- DynamoDB を使う統合テストを追加する場合は、テスト用の DynamoDB エンドポイント設定または Testcontainers の検討が必要

## AI アシスタント向けガイドライン

1. **最小限の変更**: 依頼された範囲のみ修正する。無関係なリファクタリングや過剰な抽象化は避ける
2. **既存パターンに従う**: コントローラーは `@Controller` + Thymeleaf、DynamoDB は AWS SDK v2 の既存スタイルを踏襲する
3. **日本語**: コメント・ドキュメント・コミットメッセージは日本語で記述する（ユーザー設定に準拠）
4. **シークレットをコミットしない**: AWS 認証情報、tfstate、`.terraform/` ディレクトリはコミット対象外
5. **ビルド確認**: Java コード変更後は `./gradlew test` でテストが通ることを確認する
6. **Docker 連携**: アプリの動作確認は `docker-compose` 環境を前提とする（DynamoDB Local が必要）
7. **本番とローカルの分離**: 本番向け変更は `application-prod.properties` や Terraform に閉じ、ローカル開発体験を壊さない

## 参考

- 詳細なセットアップ・トラブルシューティング: [README.md](./README.md)
