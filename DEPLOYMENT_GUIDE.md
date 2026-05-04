# Hướng Dẫn Triển Khai (Deploy) Web Cập Nhật Lên Máy Chủ

Mỗi khi bạn sửa code giao diện Web và muốn đưa lên máy chủ `hotrocntt.bvkhanhhoa.cloud` (172.16.3.27), hãy làm chuẩn theo các bước sau để đảm bảo nhận code mới 100%, không bị lỗi cache của Cloudflare hay trình duyệt.

## Bước 1: Build & Tạo File Nén (Trên Máy Của Bạn)
1. Mở Terminal trong thư mục project `ticketmanagement`.
2. Chạy lệnh sau để Flutter tạo bản build web mới nhất:
   ```powershell
   flutter build web --release --base-href / --no-tree-shake-icons
   ```
3. Sau khi build xong, **bạn cần tự động phá cache Cloudflare** bằng cách chạy đoạn script PowerShell sau đây (bạn có thể lưu đoạn code này thành file `build_deploy.ps1` để sau này gọi cho nhanh):
   ```powershell
   $timestamp = Get-Date -Format "yyyyMMddHHmmss"
   $appDir = "build\web"

   # Sửa flutter_bootstrap.js
   $bootstrapPath = "$appDir\flutter_bootstrap.js"
   $bootstrap = Get-Content $bootstrapPath -Raw
   $bootstrap = $bootstrap -replace '"mainJsPath":"main.dart.js"', "`"mainJsPath`":`"main.dart.js?v=$timestamp`""
   Set-Content $bootstrapPath $bootstrap -NoNewline

   # Sửa index.html
   $indexPath = "$appDir\index.html"
   $index = Get-Content $indexPath -Raw
   $index = $index -replace 'src="flutter_bootstrap.js.*?"', "src=`"flutter_bootstrap.js?v=$timestamp`""
   Set-Content $indexPath $index -NoNewline

   # Tạo file nén
   $zipPath = "web_build_FINAL.zip"
   Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
   Compress-Archive -Path "$appDir\*" -DestinationPath $zipPath -Force
   Write-Host "Xong! File web_build_FINAL.zip da san sang."
   ```

## Bước 2: Copy Lên Máy Chủ
- Copy file **`web_build_FINAL.zip`** (vừa tạo ra ở thư mục `ticketmanagement`) sang máy chủ `172.16.3.27` thông qua Remote Desktop.

## Bước 3: Cập Nhật File Trên Máy Chủ
> **LƯU Ý QUAN TRỌNG:** Máy chủ của bạn dùng **IIS** (chứ không phải Serverpod) để chạy Web. Thư mục chứa Web của IIS hiện tại đang nằm ở **`C:\web_build`** (như bạn đã cấu hình). TUYỆT ĐỐI KHÔNG giải nén vào thư mục của backend Serverpod (`C:\backend_full\...`).

1. Mở thư mục **`C:\web_build`** trên máy chủ (172.16.3.27).
2. **Xóa sạch** tất cả các file và thư mục cũ bên trong `C:\web_build` (gồm: assets, canvaskit, index.html, main.dart.js...).
3. **Giải nén** toàn bộ nội dung của file `web_build_FINAL.zip` thả vào thư mục `C:\web_build`.

## Bước 4: Kiểm Tra
- Mở trình duyệt, vào trang `https://hotrocntt.bvkhanhhoa.cloud`
- Ấn **`Ctrl + F5`** (hoặc `Ctrl + Shift + R`) để tải lại trang lần đầu.
- Done! Code mới đã được cập nhật hoàn hảo.
