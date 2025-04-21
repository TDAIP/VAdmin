# VAdmin - Hệ thống Admin cho Roblox

VAdmin là một hệ thống quản trị mạnh mẽ và dễ sử dụng cho game Roblox, với đầy đủ tính năng quản lý người chơi và bảo mật cao.

## Tính năng

* Hệ thống phân quyền 5 cấp (0-4)
* UI thông báo đẹp mắt
* Hỗ trợ command qua thanh chat (tự động ban đầu với `/` hoặc `!`)
* Lưu trữ người dùng bị cấm qua DataStore
* Nhiều lệnh hữu ích cho việc quản lý game

## Cài đặt

### Cách 1: Sử dụng script installer
1. Tạo một Script trong ServerScriptService
2. Dán nội dung của `VAdminInstaller.lua` vào script đó
3. Chạy game
4. VAdmin sẽ tự động được cài đặt

### Cách 2: Cài đặt thủ công
1. Tạo thư mục VAdmin trong ServerStorage
2. Tạo các module script cần thiết như trong cấu trúc folder
3. Tạo script VAdminStarter trong ServerScriptService
4. Tạo LocalScript VAdminClient trong ReplicatedStorage hoặc StarterPlayerScripts

## Sử dụng

### Cấp độ quyền
* 0 - Người chơi thường
* 1 - Điều hành viên (Mod)
* 2 - Quản trị viên (Admin)
* 3 - Quản trị viên cấp cao (Super Admin)
* 4 - Chủ sở hữu game (Owner)

### Lệnh có sẵn
VAdmin đi kèm với nhiều lệnh hữu ích:

| Lệnh | Mô tả | Cấp |
|------|-------|-----|
| !help, !cmds | Hiển thị tất cả lệnh | 0 |
| !kick | Đuổi người chơi | 1 |
| !heal | Hồi máu cho người chơi | 1 |
| !kill | Giết người chơi | 2 |
| !ban | Cấm người chơi | 2 |
| !unban | Bỏ cấm người chơi | 2 |
| !setrank | Đặt cấp admin cho người chơi | 3 |
| !message | Gửi thông báo đến tất cả người chơi | 2 |
| !shutdown | Tắt server | 4 |

Và nhiều lệnh khác...

## Tùy chỉnh

Bạn có thể dễ dàng thêm lệnh mới bằng cách chỉnh sửa CommandManager. Hãy xem mã trong module để biết thêm chi tiết.

## Cấu trúc

```
VAdmin/
│
├── Core.lua - Module trung tâm điều phối
├── Init.lua - Module khởi tạo
├── UI.lua - Module giao diện người dùng
│
├── Modules/
│   ├── Utils.lua - Tiện ích
│   ├── DataManager.lua - Quản lý dữ liệu
│   ├── PermissionManager.lua - Quản lý quyền
│   └── CommandManager.lua - Quản lý lệnh
│
└── VAdminInstaller.lua - Script cài đặt
```

## Hỗ trợ

Nếu bạn gặp vấn đề khi sử dụng VAdmin, hãy báo cáo lỗi hoặc đề xuất tính năng mới.