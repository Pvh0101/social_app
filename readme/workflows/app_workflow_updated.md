# Luồng Hệ Thống Ứng Dụng Social App

## 1. Xác thực và Quản lý Người dùng

### 1.1. Đăng ký tài khoản
1. Người dùng nhập email, mật khẩu và xác nhận mật khẩu
2. Hệ thống kiểm tra tính hợp lệ của dữ liệu đầu vào
3. Firebase Authentication tạo tài khoản người dùng mới
4. Hệ thống tạo document người dùng trong Firestore với thông tin cơ bản
5. Hệ thống gửi email xác minh đến địa chỉ email đã đăng ký
6. Người dùng được chuyển đến màn hình xác minh email

### 1.2. Xác minh email
1. Người dùng nhận email xác minh và nhấp vào liên kết
2. Firebase Authentication cập nhật trạng thái xác minh email
3. Khi người dùng quay lại ứng dụng, hệ thống kiểm tra trạng thái xác minh
4. Nếu đã xác minh, người dùng được chuyển đến màn hình nhập thông tin cá nhân
5. Nếu chưa xác minh, người dùng có thể yêu cầu gửi lại email xác minh

### 1.3. Nhập thông tin cá nhân
1. Người dùng nhập thông tin cá nhân (họ tên, ngày sinh, giới tính, số điện thoại)
2. Hệ thống kiểm tra tính hợp lệ của dữ liệu
3. Người dùng có thể tải lên ảnh đại diện
4. Hệ thống lưu thông tin vào Firestore và ảnh đại diện vào Firebase Storage
5. Người dùng được chuyển đến màn hình chính của ứng dụng

### 1.4. Đăng nhập
1. Người dùng nhập email và mật khẩu
2. Firebase Authentication xác thực thông tin đăng nhập
3. Hệ thống kiểm tra trạng thái xác minh email
4. Hệ thống kiểm tra tính đầy đủ của thông tin cá nhân
5. Hệ thống cập nhật token FCM và trạng thái online
6. Người dùng được chuyển đến màn hình chính hoặc màn hình phù hợp với trạng thái tài khoản

### 1.5. Đăng xuất
1. Người dùng chọn đăng xuất từ menu
2. Hệ thống cập nhật trạng thái offline và thời gian hoạt động cuối
3. Hệ thống xóa token FCM khỏi Firestore
4. Firebase Authentication đăng xuất người dùng
5. Người dùng được chuyển đến màn hình đăng nhập

## 2. Trang chủ và Feed

### 2.1. Hiển thị Feed bài viết
1. Hệ thống truy vấn Firestore để lấy bài viết từ người dùng đang theo dõi
2. Hệ thống sắp xếp bài viết theo thời gian tạo (mới nhất lên đầu)
3. Hệ thống tải thông tin người đăng và số lượng tương tác cho mỗi bài viết
4. Hệ thống hiển thị bài viết dưới dạng danh sách cuộn vô hạn
5. Khi người dùng cuộn đến cuối danh sách, hệ thống tải thêm bài viết

### 2.2. Hiển thị Feed video
1. Hệ thống truy vấn Firestore để lấy bài viết có loại là video
2. Hệ thống tải thông tin người đăng và số lượng tương tác cho mỗi video
3. Hệ thống hiển thị video dưới dạng danh sách cuộn dọc (kiểu TikTok)
4. Video tự động phát khi hiển thị trên màn hình và tạm dừng khi không còn hiển thị
5. Khi người dùng cuộn đến video cuối, hệ thống tải thêm video

### 2.3. Tương tác với bài viết
1. Người dùng có thể thích bài viết bằng cách nhấn nút thích
2. Hệ thống cập nhật trạng thái thích trong Firestore và cập nhật số lượng thích
3. Người dùng có thể bình luận bằng cách nhấn vào phần bình luận
4. Hệ thống hiển thị danh sách bình luận và cho phép thêm bình luận mới
5. Người dùng có thể chia sẻ bài viết bằng cách nhấn nút chia sẻ

## 3. Đăng bài và Quản lý Nội dung

### 3.1. Tạo bài viết mới
1. Người dùng chọn tạo bài viết mới từ màn hình chính
2. Người dùng nhập nội dung văn bản cho bài viết
3. Người dùng có thể thêm hình ảnh hoặc video (tối đa 10 file)
4. Nếu là video, hệ thống tạo thumbnail tự động
5. Khi nhấn đăng, hệ thống tải file lên Firebase Storage
6. Hệ thống tạo document bài viết mới trong Firestore với các thông tin liên quan
7. Hệ thống cập nhật feed của người theo dõi

### 3.2. Chỉnh sửa bài viết
1. Người dùng chọn tùy chọn chỉnh sửa từ menu của bài viết
2. Hệ thống hiển thị form chỉnh sửa với nội dung hiện tại
3. Người dùng thay đổi nội dung văn bản (không thể thay đổi media)
4. Khi nhấn cập nhật, hệ thống cập nhật document bài viết trong Firestore
5. Hệ thống cập nhật thời gian chỉnh sửa và đánh dấu bài viết đã được chỉnh sửa

### 3.3. Xóa bài viết
1. Người dùng chọn tùy chọn xóa từ menu của bài viết
2. Hệ thống hiển thị hộp thoại xác nhận
3. Khi xác nhận, hệ thống xóa document bài viết từ Firestore
4. Hệ thống xóa các file media liên quan từ Firebase Storage
5. Hệ thống xóa tất cả bình luận và lượt thích liên quan đến bài viết

### 3.4. Báo cáo bài viết
1. Người dùng chọn tùy chọn báo cáo từ menu của bài viết
2. Hệ thống hiển thị form báo cáo với các lý do
3. Người dùng chọn lý do và thêm mô tả (tùy chọn)
4. Hệ thống tạo document báo cáo mới trong Firestore
5. Quản trị viên sẽ xem xét báo cáo và thực hiện hành động phù hợp

## 4. Hệ thống Nhắn tin

### 4.1. Danh sách cuộc trò chuyện
1. Hệ thống truy vấn Firestore để lấy tất cả cuộc trò chuyện của người dùng
2. Hệ thống sắp xếp cuộc trò chuyện theo thời gian tin nhắn mới nhất
3. Hệ thống hiển thị thông tin cơ bản: ảnh đại diện, tên, tin nhắn cuối, thời gian
4. Hệ thống đánh dấu cuộc trò chuyện có tin nhắn chưa đọc
5. Hệ thống lắng nghe sự thay đổi trong thời gian thực để cập nhật danh sách

### 4.2. Tạo cuộc trò chuyện mới
1. Người dùng chọn tạo cuộc trò chuyện mới từ màn hình danh sách
2. Hệ thống hiển thị danh sách bạn bè để chọn
3. Người dùng chọn một hoặc nhiều người để tạo cuộc trò chuyện
4. Hệ thống kiểm tra xem cuộc trò chuyện đã tồn tại chưa
5. Nếu chưa, hệ thống tạo document cuộc trò chuyện mới trong Firestore
6. Người dùng được chuyển đến màn hình chat

### 4.3. Tạo nhóm chat
1. Người dùng chọn tạo nhóm chat từ màn hình danh sách
2. Người dùng nhập tên nhóm và chọn ảnh nhóm (tùy chọn)
3. Người dùng chọn các thành viên từ danh sách bạn bè
4. Hệ thống tạo document nhóm chat mới trong Firestore
5. Hệ thống tải ảnh nhóm lên Firebase Storage (nếu có)
6. Người dùng được chuyển đến màn hình chat nhóm

### 4.4. Gửi và nhận tin nhắn
1. Hệ thống truy vấn Firestore để lấy lịch sử tin nhắn của cuộc trò chuyện
2. Hệ thống hiển thị tin nhắn theo thứ tự thời gian
3. Người dùng nhập tin nhắn mới và nhấn gửi
4. Hệ thống tạo document tin nhắn mới trong Firestore
5. Hệ thống cập nhật thông tin cuộc trò chuyện (tin nhắn cuối, thời gian)
6. Hệ thống gửi thông báo đẩy đến các thành viên khác trong cuộc trò chuyện
7. Các thành viên khác nhận được tin nhắn trong thời gian thực thông qua Firestore listeners

### 4.5. Gửi file media trong chat
1. Người dùng chọn tùy chọn đính kèm file
2. Người dùng chọn hình ảnh hoặc video từ thư viện hoặc chụp mới
3. Hệ thống tải file lên Firebase Storage
4. Hệ thống tạo document tin nhắn mới với URL của file
5. Hệ thống hiển thị hình ảnh hoặc video trong cuộc trò chuyện
6. Người nhận có thể xem trước hoặc tải xuống file

### 4.6. Quản lý nhóm chat
1. Người dùng chọn xem thông tin nhóm từ màn hình chat
2. Hệ thống hiển thị thông tin nhóm và danh sách thành viên
3. Người tạo nhóm có thể thêm/xóa thành viên, đổi tên nhóm, đổi ảnh nhóm
4. Thành viên có thể rời nhóm
5. Hệ thống cập nhật thông tin nhóm trong Firestore

## 5. Kết bạn và Theo dõi

### 5.1. Tìm kiếm người dùng
1. Người dùng nhập từ khóa tìm kiếm (tên, email)
2. Hệ thống truy vấn Firestore để tìm người dùng phù hợp
3. Hệ thống hiển thị kết quả tìm kiếm với thông tin cơ bản
4. Người dùng có thể xem hồ sơ của người dùng khác từ kết quả tìm kiếm

### 5.2. Gửi lời mời kết bạn
1. Người dùng chọn gửi lời mời kết bạn từ hồ sơ người dùng khác
2. Hệ thống tạo document lời mời kết bạn trong Firestore
3. Hệ thống gửi thông báo đẩy đến người nhận
4. Trạng thái nút kết bạn thay đổi thành "Đã gửi lời mời"

### 5.3. Quản lý lời mời kết bạn
1. Người dùng xem danh sách lời mời kết bạn từ màn hình thông báo
2. Hệ thống truy vấn Firestore để lấy tất cả lời mời kết bạn đến
3. Người dùng có thể chấp nhận hoặc từ chối lời mời
4. Khi chấp nhận, hệ thống tạo mối quan hệ bạn bè trong Firestore
5. Hệ thống xóa document lời mời kết bạn
6. Hệ thống gửi thông báo đến người gửi lời mời

### 5.4. Theo dõi người dùng
1. Người dùng chọn theo dõi từ hồ sơ người dùng khác
2. Hệ thống tạo document theo dõi trong Firestore
3. Hệ thống cập nhật số lượng người theo dõi của người được theo dõi
4. Hệ thống cập nhật số lượng đang theo dõi của người theo dõi
5. Hệ thống gửi thông báo đến người được theo dõi

### 5.5. Quản lý danh sách bạn bè
1. Người dùng xem danh sách bạn bè từ màn hình bạn bè
2. Hệ thống truy vấn Firestore để lấy tất cả mối quan hệ bạn bè
3. Hệ thống hiển thị danh sách bạn bè với thông tin cơ bản và trạng thái online
4. Người dùng có thể hủy kết bạn hoặc chặn người dùng khác
5. Khi hủy kết bạn, hệ thống xóa mối quan hệ bạn bè từ Firestore

## 6. Hệ thống Thông báo

### 6.1. Thông báo trong ứng dụng
1. Hệ thống truy vấn Firestore để lấy tất cả thông báo của người dùng
2. Hệ thống sắp xếp thông báo theo thời gian (mới nhất lên đầu)
3. Hệ thống hiển thị thông báo với thông tin: loại, nội dung, thời gian
4. Hệ thống đánh dấu thông báo chưa đọc
5. Khi người dùng nhấn vào thông báo, hệ thống chuyển đến nội dung liên quan
6. Hệ thống đánh dấu thông báo đã đọc

### 6.2. Thông báo đẩy
1. Khi có sự kiện mới (tin nhắn, lời mời kết bạn, thích, bình luận), hệ thống tạo thông báo
2. Hệ thống lưu thông báo vào Firestore
3. Cloud Functions gửi thông báo đẩy đến thiết bị của người dùng thông qua FCM
4. Người dùng nhận được thông báo ngay cả khi không mở ứng dụng
5. Khi nhấn vào thông báo, ứng dụng mở và chuyển đến nội dung liên quan

### 6.3. Cài đặt thông báo
1. Người dùng truy cập cài đặt thông báo từ menu cài đặt
2. Người dùng có thể bật/tắt các loại thông báo khác nhau
3. Người dùng có thể cài đặt thời gian không làm phiền
4. Hệ thống lưu cài đặt thông báo vào Firestore
5. Hệ thống áp dụng cài đặt khi gửi thông báo đẩy

## 7. Hồ sơ Người dùng

### 7.1. Xem hồ sơ cá nhân
1. Người dùng truy cập hồ sơ cá nhân từ menu
2. Hệ thống truy vấn Firestore để lấy thông tin người dùng
3. Hệ thống truy vấn Firestore để lấy bài viết của người dùng
4. Hệ thống hiển thị thông tin cá nhân, số liệu thống kê và danh sách bài viết
5. Người dùng có thể chuyển đổi giữa chế độ xem lưới và danh sách

### 7.2. Xem hồ sơ người dùng khác
1. Người dùng truy cập hồ sơ người dùng khác từ bài viết, bình luận hoặc tìm kiếm
2. Hệ thống kiểm tra mối quan hệ giữa hai người dùng
3. Hệ thống kiểm tra cài đặt quyền riêng tư của người dùng được xem
4. Hệ thống hiển thị thông tin và bài viết dựa trên quyền riêng tư
5. Người dùng có thể thực hiện các hành động: kết bạn, theo dõi, nhắn tin

### 7.3. Chỉnh sửa hồ sơ
1. Người dùng chọn chỉnh sửa hồ sơ từ hồ sơ cá nhân
2. Hệ thống hiển thị form chỉnh sửa với thông tin hiện tại
3. Người dùng có thể thay đổi: ảnh đại diện, tên, mô tả, thông tin cá nhân
4. Khi lưu, hệ thống cập nhật thông tin trong Firestore
5. Hệ thống tải ảnh đại diện mới lên Firebase Storage (nếu thay đổi)

### 7.4. Cài đặt quyền riêng tư
1. Người dùng truy cập cài đặt quyền riêng tư từ menu cài đặt
2. Người dùng có thể cài đặt tài khoản công khai hoặc riêng tư
3. Người dùng có thể cài đặt ai có thể xem bài viết, gửi tin nhắn, thấy trạng thái online
4. Hệ thống lưu cài đặt quyền riêng tư vào Firestore
5. Hệ thống áp dụng cài đặt khi người khác truy cập hồ sơ

## 8. Cài đặt Ứng dụng

### 8.1. Cài đặt ngôn ngữ
1. Người dùng truy cập cài đặt ngôn ngữ từ menu cài đặt
2. Hệ thống hiển thị danh sách ngôn ngữ được hỗ trợ
3. Người dùng chọn ngôn ngữ mong muốn
4. Hệ thống lưu cài đặt ngôn ngữ vào SharedPreferences
5. Hệ thống áp dụng ngôn ngữ mới ngay lập tức

### 8.2. Cài đặt giao diện
1. Người dùng truy cập cài đặt giao diện từ menu cài đặt
2. Người dùng có thể chọn chế độ sáng, tối hoặc theo hệ thống
3. Hệ thống lưu cài đặt giao diện vào SharedPreferences
4. Hệ thống áp dụng giao diện mới ngay lập tức

### 8.3. Cài đặt tài khoản
1. Người dùng truy cập cài đặt tài khoản từ menu cài đặt
2. Người dùng có thể thay đổi mật khẩu, email
3. Người dùng có thể vô hiệu hóa hoặc xóa tài khoản
4. Hệ thống xác thực người dùng trước khi thực hiện các thay đổi quan trọng
5. Hệ thống cập nhật thông tin trong Firebase Authentication và Firestore

## 9. Luồng Dữ liệu và Đồng bộ hóa

### 9.1. Đồng bộ hóa dữ liệu
1. Ứng dụng sử dụng Firestore listeners để lắng nghe thay đổi trong thời gian thực
2. Khi có thay đổi từ server, hệ thống cập nhật UI tự động
3. Hệ thống sử dụng caching để giảm thiểu truy vấn và cải thiện hiệu suất
4. Hệ thống kiểm tra kết nối internet và xử lý trường hợp offline
5. Khi kết nối lại, hệ thống đồng bộ hóa các thay đổi offline với server

### 9.2. Quản lý trạng thái
1. Ứng dụng sử dụng Riverpod để quản lý trạng thái toàn cục
2. Mỗi tính năng có các provider riêng để quản lý trạng thái
3. Hệ thống sử dụng repository pattern để tách biệt logic nghiệp vụ và nguồn dữ liệu
4. Hệ thống sử dụng state notifier để quản lý trạng thái phức tạp
5. UI được cập nhật tự động khi trạng thái thay đổi thông qua Consumer widgets

### 9.3. Xử lý lỗi và khôi phục
1. Hệ thống bắt và xử lý các ngoại lệ trong quá trình tương tác với Firebase
2. Hệ thống hiển thị thông báo lỗi phù hợp cho người dùng
3. Hệ thống tự động thử lại các hoạt động mạng khi gặp lỗi tạm thời
4. Hệ thống lưu trữ dữ liệu quan trọng cục bộ để khôi phục khi cần
5. Hệ thống ghi log lỗi để phân tích và cải thiện 