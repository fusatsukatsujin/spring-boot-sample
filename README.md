# Spring Boot モニタリングサンプルプロジェクト

Spring Bootアプリケーションを各種モニタリングサービス（Prometheus、Grafana、Loki）で監視するサンプルプロジェクトです。

## 概要

このプロジェクトは、Spring Bootアプリケーションのメトリクスとログを収集・可視化するための統合監視環境を提供します。

### 主な機能

- **メトリクス監視**: Prometheus + Grafanaでアプリケーションのメトリクスを可視化
- **ログ監視**: Loki + Promtail + Grafanaでアプリケーションのログを可視化
- **統合ダッシュボード**: Grafanaでメトリクスとログを同じ画面で確認可能
- **ローカル開発環境**: Docker Composeですべてのサービスを起動

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│              Docker Compose 環境                         │
│                                                          │
│  ┌──────────────┐      ┌──────────────┐                │
│  │ Spring Boot  │      │  DynamoDB    │                │
│  │   App        │◄─────┤  Local       │                │
│  │  :8080       │      │  :8000       │                │
│  └───┬──────┬───┘      └──────────────┘                │
│      │      │                                           │
│      │      │ ログ (標準出力)                            │
│      │      ▼                                           │
│      │  ┌──────────────┐                               │
│      │  │  Promtail    │                               │
│      │  │              │                               │
│      │  └──────┬───────┘                               │
│      │         │ ログ送信                                │
│      │         ▼                                       │
│      │  ┌──────────────┐                               │
│      │  │    Loki      │                               │
│      │  │   :3100     │                               │
│      │  └──────┬───────┘                               │
│      │         │                                       │
│      │ メトリクス (HTTP)                                 │
│      ▼         │                                       │
│  ┌──────────────┐      │                               │
│  │ Prometheus   │      │                               │
│  │  :9090       │      │                               │
│  └──────┬───────┘      │                               │
│         │              │                               │
│         │              │ データソース                  │
│         │              ▼                               │
│         │      ┌──────────────┐                       │
│         └─────►│   Grafana    │◄──────┘               │
│                │   :3000      │                       │
│                └──────────────┘                       │
└─────────────────────────────────────────────────────────┘

データフロー:
- メトリクス: Spring Boot App → Prometheus → Grafana
- ログ: Spring Boot App → Promtail → Loki → Grafana
```

## 技術スタック

### アプリケーション
- **Spring Boot 3.3.6**
- **Java 17**
- **Thymeleaf** (テンプレートエンジン)
- **DynamoDB** (データベース)

### モニタリング
- **Prometheus**: メトリクス収集・保存
- **Grafana**: 可視化・ダッシュボード
- **Loki**: ログ収集・保存
- **Promtail**: ログ収集エージェント

### インフラ
- **Docker Compose**: ローカル開発環境
- **DynamoDB Local**: ローカルDynamoDBエミュレータ

## セットアップ

### 前提条件

- Docker Desktop (または Docker + Docker Compose)
- Java 17以上
- Gradle 8.5以上

### 起動方法

1. **リポジトリのクローン**
   ```bash
   git clone <repository-url>
   cd spring-boot-demo
   ```

2. **Docker Composeで全サービスを起動**
   ```bash
   docker-compose up -d
   ```

3. **アプリケーションのビルド（初回のみ）**
   ```bash
   ./gradlew build
   ```

4. **アプリケーションの再ビルド（依存関係変更時）**
   ```bash
   docker-compose build app
   docker-compose up -d app
   ```

## アクセス方法

### アプリケーション
- **URL**: http://localhost:8080
- **機能**: ユーザー登録・一覧表示（DynamoDB使用）

### モニタリングサービス

#### Grafana
- **URL**: http://localhost:3000
- **ログイン**: `admin` / `admin`
- **機能**: 
  - メトリクスの可視化（Prometheusデータソース）
  - ログの可視化（Lokiデータソース）
  - ダッシュボードの作成

#### Prometheus
- **URL**: http://localhost:9090
- **機能**: 
  - メトリクスの確認
  - PromQLクエリの実行
  - ターゲットの状態確認

#### Loki
- **URL**: http://localhost:3100
- **機能**: 
  - ログの確認（API経由）
  - LogQLクエリの実行

#### DynamoDB Admin
- **URL**: http://localhost:8001
- **機能**: DynamoDBテーブル・データの確認

## 使用方法

### Grafanaでメトリクスを確認

1. Grafanaにログイン（http://localhost:3000）
2. 左メニューの「Explore」をクリック
3. データソースで「Prometheus」を選択
4. クエリ欄に以下を入力：
   ```
   jvm_memory_used_bytes
   ```
5. 「Run query」をクリック

### Grafanaでログを確認

1. Grafanaにログイン（http://localhost:3000）
2. 左メニューの「Explore」をクリック
3. データソースで「Loki」を選択
4. クエリ欄に以下を入力：
   ```
   {compose_service="app"}
   ```
5. 「Run query」をクリック

### よく使うメトリクス例

```promql
# JVMメモリ使用量
jvm_memory_used_bytes

# HTTPリクエスト数
http_server_requests_seconds_count

# アプリケーション起動時間
application_started_time_seconds

# スレッド数
jvm_threads_live_threads

# ガベージコレクション
jvm_gc_pause_seconds_sum
```

### よく使うログクエリ例

```logql
# すべてのログ
{compose_service="app"}

# エラーログのみ
{compose_service="app"} |= "ERROR"

# 特定の文字列を含むログ
{compose_service="app"} |= "Spring"
```

## プロジェクト構成

```
spring-boot-demo/
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   ├── controller/      # コントローラー
│   │   │   ├── config/          # 設定クラス
│   │   │   └── DemoApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── logback-spring.xml
│   └── test/                     # テストコード
├── prometheus/
│   └── prometheus.yml           # Prometheus設定
├── loki/
│   └── loki-config.yml          # Loki設定
├── promtail/
│   └── promtail-config.yml      # Promtail設定
├── grafana/
│   └── provisioning/
│       └── datasources/         # Grafanaデータソース設定
│           ├── prometheus.yml
│           └── loki.yml
├── docker-compose.yml            # Docker Compose設定
├── Dockerfile                    # アプリケーションDockerfile
└── build.gradle                  # Gradle設定
```

## 主要な設定

### Spring Boot Actuator

`application.properties`で以下のエンドポイントが有効化されています：

- `/actuator/prometheus`: Prometheus形式のメトリクス
- `/actuator/health`: ヘルスチェック
- `/actuator/metrics`: メトリクス一覧
- `/actuator/info`: アプリケーション情報

### ログ設定

`logback-spring.xml`で以下のログ出力先が設定されています：

- **標準出力**: Dockerログとして出力（Promtailが収集）
- **AWS CloudWatch Logs**: 本番環境用（AWS環境で有効）

## トラブルシューティング

### Prometheusがメトリクスを取得できない

1. アプリケーションが起動しているか確認
   ```bash
   docker-compose ps app
   ```

2. Actuatorエンドポイントにアクセスできるか確認
   ```bash
   curl http://localhost:8080/actuator/prometheus
   ```

3. Prometheusのターゲット状態を確認
   - http://localhost:9090 → Status → Targets

### Lokiでログが表示されない

1. Promtailが正常に動作しているか確認
   ```bash
   docker-compose logs promtail
   ```

2. Lokiが正常に動作しているか確認
   ```bash
   docker-compose logs loki
   ```

3. アプリケーションのログが出力されているか確認
   ```bash
   docker-compose logs app
   ```

### Grafanaでデータソースが見つからない

1. Grafanaを再起動
   ```bash
   docker-compose restart grafana
   ```

2. データソース設定ファイルを確認
   - `grafana/provisioning/datasources/prometheus.yml`
   - `grafana/provisioning/datasources/loki.yml`

## コマンドリファレンス

### サービスの起動・停止

```bash
# 全サービスを起動
docker-compose up -d

# 全サービスを停止
docker-compose down

# 特定のサービスを再起動
docker-compose restart <service-name>

# サービスの状態確認
docker-compose ps

# ログの確認
docker-compose logs <service-name>
```

### アプリケーションの再ビルド

```bash
# アプリケーションを再ビルド
docker-compose build app

# 再ビルドして再起動
docker-compose up -d --build app
```

## 本番環境への展開

このプロジェクトには、AWS環境への展開用のTerraform設定も含まれています：

- `terraform/infrastructure/`: インフラストラクチャ（ECR、DynamoDB、VPC等）
- `terraform/application/`: アプリケーション（ECS、タスク定義等）

詳細は各ディレクトリのREADMEを参照してください。

## ライセンス

このプロジェクトはサンプルコードです。

## 参考資料

- [Spring Boot Actuator](https://docs.spring.io/spring-boot/reference/actuator.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)

