#!/bin/bash

# setup.sh - Kiểm tra và cài đặt môi trường cho dự án Product Tracking
# Tự động tải xuống và cài đặt: Go, Flutter (nếu chưa có)
# Hướng dẫn cài đặt: Docker (do yêu cầu quyền root/system sâu)

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== BẮT ĐẦU KIỂM TRA MÔI TRƯỜNG ===${NC}"

# Kiểm tra quyền root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}!!! CẢNH BÁO: BẠN ĐANG CHẠY SCRIPT DƯỚI QUYỀN ROOT !!!${NC}"
    echo -e "${YELLOW}Flutter và Go khuyến nghị cài đặt cho user thường để tránh lỗi permission.${NC}"
    echo -e "${YELLOW}Script này được thiết kế để chạy dưới quyền user thường và sẽ hỏi password sudo khi cần.${NC}"
    echo -e "Nếu bạn tiếp tục, Flutter sẽ cảnh báo và có thể không hoạt động đúng."
    read -p "Bạn có chắc chắn muốn tiếp tục không? (y/N): " confirm_root
    if [[ "$confirm_root" != "y" && "$confirm_root" != "Y" ]]; then
        echo -e "${GREEN}Đã hủy. Vui lòng chạy lại script KHÔNG dùng sudo (ví dụ: ./scripts/setup.sh)${NC}"
        exit 1
    fi
fi

# Hàm kiểm tra command
check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}✔ $1 đã được cài đặt: $( $1 --version | head -n 1 )${NC}"
        return 0
    else
        echo -e "${YELLOW}✘ $1 chưa được cài đặt.${NC}"
        return 1
    fi
}

# 1. Kiểm tra các công cụ cơ bản (curl, git, make, tar, unzip)
echo -e "\n${BLUE}[1/4] Kiểm tra công cụ hệ thống cơ bản...${NC}"
REQUIRED_SYS_TOOLS=("curl" "git" "make" "tar" "unzip")
MISSING_SYS_TOOLS=()

for tool in "${REQUIRED_SYS_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_SYS_TOOLS+=("$tool")
    else
        echo -e "${GREEN}✔ $tool OK${NC}"
    fi
done

if [ ${#MISSING_SYS_TOOLS[@]} -ne 0 ]; then
    echo -e "${RED}Thiếu các công cụ cơ bản: ${MISSING_SYS_TOOLS[*]}. Đang thử cài đặt bằng apt-get (cần sudo)...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "${MISSING_SYS_TOOLS[@]}"
    else
        echo -e "${RED}Không tìm thấy apt-get. Vui lòng cài đặt thủ công: ${MISSING_SYS_TOOLS[*]}${NC}"
        exit 1
    fi
fi

# 2. Kiểm tra Docker
echo -e "\n${BLUE}[2/4] Kiểm tra Docker...${NC}"
if check_cmd "docker"; then
    echo "Docker đã sẵn sàng."
else
    echo -e "${YELLOW}Đang tải script cài đặt Docker tu dong...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    echo -e "${YELLOW}Vui lòng chạy lệnh sau để cài Docker (yêu cầu quyền root):${NC}"
    echo -e "  sudo sh get-docker.sh"
    echo -e "${YELLOW}Sau đó thêm user hiện tại vào group docker:${NC}"
    echo -e "  sudo usermod -aG docker \$USER && newgrp docker"
fi

# 3. Kiểm tra Golang
echo -e "\n${BLUE}[3/4] Kiểm tra Golang...${NC}"
GO_VERSION="1.21.5"
GO_TAR="go$GO_VERSION.linux-amd64.tar.gz"
INSTALL_DIR="$HOME/.local/go"
if ! command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Go chưa có. Đang tự động tải về phiên bản $GO_VERSION ...${NC}"
    cd /tmp
    curl -OL "https://go.dev/dl/$GO_TAR"
    
    echo -e "${YELLOW}Đang giải nén vào $INSTALL_DIR ...${NC}"
    mkdir -p "$HOME/.local"
    rm -rf "$INSTALL_DIR"
    tar -C "$HOME/.local" -xzf "$GO_TAR"
    # Lưu ý: tar file go thường chứa thư mục 'go', nên nó sẽ giải nén thành $HOME/.local/go
    
    # Setup PATH tạm thời cho script này
    export PATH=$PATH:$INSTALL_DIR/bin
    
    # Cấu hình shell
    SHELL_PROFILE="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then SHELL_PROFILE="$HOME/.zshrc"; fi
    
    if ! grep -q "$INSTALL_DIR/bin" "$SHELL_PROFILE"; then
        echo -e "${GREEN}Cập nhật PATH vào $SHELL_PROFILE ...${NC}"
        echo "export PATH=\$PATH:$INSTALL_DIR/bin" >> "$SHELL_PROFILE"
        echo "export GOPATH=$HOME/go" >> "$SHELL_PROFILE"
        echo "export PATH=\$PATH:\$GOPATH/bin" >> "$SHELL_PROFILE"
    fi
    
    echo -e "${GREEN}Đã cài xong Golang. Vui lòng chạy 'source $SHELL_PROFILE' sau khi script kết thúc.${NC}"
    go version
else
    echo -e "${GREEN}✔ Go đã được cài đặt: $(go version)${NC}"
fi

# 4. Kiểm tra Node.js & npm (Frontend Mới - Next.js)
echo -e "\n${BLUE}[4/4] Kiểm tra Node.js & npm...${NC}"
if ! command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}Node.js chưa có. Đang thử cài đặt NVM và Node.js LTS...${NC}"
    
    # Cài đặt NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM ngay lập tức
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Cài đặt Node LTS
    nvm install --lts
    nvm use --lts
    
    echo -e "${GREEN}Đã cài xong Node.js: $(node -v) và npm: $(npm -v)${NC}"
else
    echo -e "${GREEN}✔ Node.js đã được cài đặt: $(node -v)${NC}"
    echo -e "${GREEN}✔ npm đã được cài đặt: $(npm -v)${NC}"
fi

echo -e "\n${BLUE}=== HOÀN TẤT ===${NC}"
echo -e "${YELLOW}Lưu ý: Nếu bạn vừa cài đặt mới Go hoặc Flutter, hãy chạy lệnh sau để cập nhật biến môi trường ngay lập tức:${NC}"
echo -e "  source ~/.bashrc  (hoặc source ~/.zshrc)"
