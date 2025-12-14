# Hướng dẫn Cài đặt & Thiết lập Môi trường

Tài liệu này hướng dẫn cách cài đặt các công cụ cần thiết để phát triển và chạy dự án **Hệ thống xác thực nguồn gốc & Chống giả mạo**.

## 1. Yêu cầu Hệ thống (Prerequisites)

Để chạy trơn tru toàn bộ stack (đặc biệt là Hyperledger Fabric), khuyến nghị cấu hình tối thiểu:
*   **OS:** Linux (Ubuntu 20.04+), macOS, hoặc Windows 10/11 (sử dụng WSL2).
*   **RAM:** Tối thiểu 8GB (khuyên dùng 16GB).
*   **CPU:** 2 cores trở lên.

## 2. Cài đặt các công cụ cốt lõi

### A. Docker & Docker Compose (Quan trọng nhất)
Hệ thống sử dụng Docker để chạy Database, Kafka, và mạng Blockchain.
*   **Tải về:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) hoặc [Docker Engine](https://docs.docker.com/engine/install/) (cho Linux).
*   **Kiểm tra cài đặt:**
    ```bash
    docker --version
    docker-compose --version
    ```
*   *Lưu ý cho người dùng Windows:* Hãy chắc chắn bạn đã bật chế độ WSL2 trong settings của Docker Desktop.

### B. Ngôn ngữ lập trình Go (Golang)
Dùng cho Backend API, Worker và Chaincode.
*   **Phiên bản:** 1.20 trở lên.
*   **Tải về:** [Go Installation](https://go.dev/doc/install)
*   **Setup biến môi trường (GOPATH):** Đảm bảo `go/bin` đã được thêm vào PATH của bạn.
*   **Kiểm tra:**
    ```bash
    go version
    ```

### C. Flutter SDK
Dùng cho ứng dụng Mobile/Web Client.
*   **Tải về:** [Flutter Install](https://flutter.dev/docs/get-started/install)
*   **Kiểm tra:**
    ```bash
    flutter doctor
    ```

## 3. Cài đặt & Cấu hình Bổ sung

### A. Công cụ hỗ trợ Hyperledger Fabric
Để thuận tiện cho việc phát triển và thao tác với mạng Fabric local, chúng ta có thể sử dụng script hoặc binaries.
*   Trong dự án này, chúng ta sẽ ưu tiên chạy qua Docker images. Tuy nhiên, bạn nên cài đặt thêm extension **IBM Blockchain Platform** (nếu dùng VS Code) hoặc tham khảo công cụ [Minifabric](https://github.com/hyperledger-labs/minifabric) để thao tác nhanh.

### B. Database Client (Optional)
Để xem dữ liệu trong PostgreSQL dễ dàng:
*   **DBeaver** hoặc **pgAdmin**.

## 4. Kiểm tra môi trường (Sanity Check)

Sau khi cài đặt xong, hãy thử chạy các lệnh sau trong terminal để đảm bảo mọi thứ đã sẵn sàng:

1.  **Git:** `git --version`
2.  **Docker:** `docker ps` (Không được báo lỗi permission denied)
3.  **Go:** `go env`
4.  **Make:** `make --version` (Thường cần thiết để chạy các Makefile script tự động hóa).

## 5. Khởi chạy dự án (Sơ lược)

*(Chi tiết sẽ được cập nhật khi source code hoàn thiện)*

1.  Clone repository:
    ```bash
    git clone <repo_url>
    cd product-tracking
    ```

2.  Khởi động hạ tầng (Infrastructure):
    ```bash
    docker-compose up -d
    ```

3.  Chạy Backend (Dev mode):
    ```bash
    cd backend/api-service
    go run main.go
    ```

4.  Chạy Frontend:
    ```bash
    cd frontend/mobile-app
    flutter run
    ```
