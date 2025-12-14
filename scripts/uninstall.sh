#!/bin/bash

# uninstall.sh - Gỡ cài đặt các công nghệ đã được cài đặt bởi setup.sh
# Bao gồm: Golang, Flutter (thư mục và biến môi trường), và Docker.

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}!!! CẢNH BÁO !!!${NC}"
echo -e "Script này sẽ gỡ bỏ các công nghệ sau:"
echo -e "1. ${BLUE}Golang${NC} (Xóa ~/.local/go và cấu hình trong .bashrc/.zshrc)"
echo -e "2. ${BLUE}Flutter${NC} (Xóa ~/development/flutter và cấu hình trong .bashrc/.zshrc)"
echo -e "3. ${BLUE}Docker${NC} (Gỡ cài đặt qua apt-get và xóa dữ liệu container/image)"
echo ""
echo -e "${YELLOW}Vui lòng chạy với quyền sudo nếu bạn muốn gỡ Docker.${NC}"
echo ""

read -p "Bạn có chắc chắn muốn tiếp tục? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Đã hủy bỏ."
    exit 0
fi

# Hàm xóa dòng cấu hình trong file profile
remove_config_line() {
    local file="$1"
    local keyword="$2"
    
    if [ -f "$file" ]; then
        if grep -q "$keyword" "$file"; then
            echo -e "Đang xóa cấu hình chứa '$keyword' trong $file..."
            # Tạo backup
            cp "$file" "${file}.bak_$(date +%s)"
            # Xóa dòng chứa keyword
            # Sử dụng pattern matching cẩn thận để tránh xóa nhầm
            sed -i "\|$keyword|d" "$file"
        fi
    fi
}

# 1. Gỡ cài đặt Golang
echo -e "\n${BLUE}[1/3] Gỡ cài đặt Golang...${NC}"
GO_DIR="$HOME/.local/go"
if [ -d "$GO_DIR" ]; then
    rm -rf "$GO_DIR"
    echo -e "${GREEN}Đã xóa thư mục $GO_DIR${NC}"
else
    echo -e "${YELLOW}Không tìm thấy thư mục $GO_DIR${NC}"
fi

# Xóa cấu hình Go
# Các dòng được thêm bởi setup.sh:
# export PATH=$PATH:$INSTALL_DIR/bin
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOPATH/bin

for profile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    remove_config_line "$profile" "$GO_DIR/bin"
    remove_config_line "$profile" "export GOPATH=$HOME/go"
    # Dòng export PATH=$PATH:$GOPATH/bin khá chung chung, nhưng setup.sh thêm nó ngay sau.
    # Tuy nhiên, nếu xóa dòng này có thể ảnh hưởng nếu user setup GOPATH khác.
    # Setup.sh setup GOPATH=$HOME/go.
    # Ta sẽ xóa nếu nó khớp chính xác.
    remove_config_line "$profile" "export PATH=\$PATH:\$GOPATH/bin"
done

# 2. Gỡ cài đặt Flutter
echo -e "\n${BLUE}[2/3] Gỡ cài đặt Flutter...${NC}"
FLUTTER_DIR="$HOME/development/flutter"
if [ -d "$FLUTTER_DIR" ]; then
    rm -rf "$FLUTTER_DIR"
    echo -e "${GREEN}Đã xóa thư mục $FLUTTER_DIR${NC}"
else
    echo -e "${YELLOW}Không tìm thấy thư mục $FLUTTER_DIR${NC}"
fi

# Xóa cấu hình Flutter
for profile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    remove_config_line "$profile" "$FLUTTER_DIR/bin"
done

# 3. Gỡ cài đặt Docker
echo -e "\n${BLUE}[3/3] Gỡ cài đặt Docker...${NC}"
if command -v docker >/dev/null 2>&1; then
    read -p "Bạn có muốn gỡ cài đặt Docker và xóa toàn bộ dữ liệu Docker không? (y/N): " docker_confirm
    if [[ "$docker_confirm" == "y" || "$docker_confirm" == "Y" ]]; then
        echo "Đang gỡ Docker..."
        
        # Kiểm tra sudo
        if [ "$EUID" -ne 0 ]; then 
            echo -e "${RED}Cần quyền root để gỡ Docker. Vui lòng nhập mật khẩu sudo:${NC}"
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
            sudo rm -rf /var/lib/docker
            sudo rm -rf /var/lib/containerd
        else
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
            rm -rf /var/lib/docker
            rm -rf /var/lib/containerd
        fi
        
        # Xóa file get-docker.sh nếu còn
        if [ -f "get-docker.sh" ]; then
            rm get-docker.sh
        fi
        
        echo -e "${GREEN}Đã gỡ cài đặt Docker.${NC}"
    else
        echo "Bỏ qua gỡ Docker."
    fi
else
    echo -e "${YELLOW}Docker không được cài đặt.${NC}"
fi

echo -e "\n${BLUE}=== HOÀN TẤT ===${NC}"
echo -e "${YELLOW}Vui lòng khởi động lại terminal hoặc chạy 'source ~/.bashrc' để cập nhật thay đổi.${NC}"
