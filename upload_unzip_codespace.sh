#!/bin/bash

# Định nghĩa URL của file ZIP và thư mục làm việc
ZIP_URL="https://github.com/TDAIP/VAdmin/raw/main/VAdminTool.zip"
WORK_DIR="$HOME/vadmin_tmp"
REPO_DIR="$HOME/VAdmin"  # Đường dẫn tới repo của bạn trong Codespace

# Kiểm tra thư mục làm việc có tồn tại không, nếu có thì xóa
if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

# Tạo thư mục làm việc mới
mkdir -p "$WORK_DIR"

# Di chuyển vào thư mục làm việc
cd "$WORK_DIR"

# Tải file ZIP từ GitHub
echo "Downloading $ZIP_URL..."
curl -L -o VAdminTool.zip "$ZIP_URL"

# Giải nén file ZIP
echo "Unzipping VAdminTool.zip..."
unzip VAdminTool.zip

# Di chuyển vào thư mục repo trong Codespace
cd "$REPO_DIR"

# Sao chép nội dung đã giải nén vào thư mục repo
echo "Copying files to repo directory..."
cp -r "$WORK_DIR"/* "$REPO_DIR/"

# Khởi tạo Git (nếu chưa có) và đẩy lên nhánh main
git add .
git commit -m "Auto unzip and upload VAdminTool"
git push origin main

echo "Upload complete."
