# MỞ ĐẦU

## 1. Tổng quan và lý do nghiên cứu

Kỷ nguyên số đã mang đến sự phát triển vượt bậc của công nghệ, trong đó mạng xã hội đã trở thành một phần không thể thiếu trong cuộc sống thường nhật của con người. Các nền tảng trực tuyến hiện nay không chỉ đóng vai trò là kênh kết nối cá nhân mà còn là không gian quan trọng trong lĩnh vực giáo dục, hoạt động thương mại và truyền thông đại chúng. Đặc biệt, với sự phổ cập của thiết bị di động thông minh, việc phát triển ứng dụng mạng xã hội trên nền tảng di động đã trở thành xu hướng tất yếu, đáp ứng nhu cầu kết nối nhanh chóng và linh hoạt của người dùng trong thời đại công nghệ số.

Xuất phát từ mong muốn nghiên cứu và ứng dụng kiến thức chuyên ngành vào thực tiễn, tôi đã lựa chọn đề tài "Xây dựng ứng dụng mạng xã hội trên nền tảng di động". Đề tài này không chỉ giúp tôi nâng cao năng lực phát triển ứng dụng thực tế mà còn tạo cơ hội để tìm hiểu và giải quyết các thách thức trong lĩnh vực giao tiếp trực tuyến, đồng thời tối ưu hóa trải nghiệm người dùng. Quá trình nghiên cứu và phát triển đã giúp tôi hiểu sâu sắc về cách xây dựng một hệ thống kết nối trực tuyến hiệu quả và bảo mật.

Hiện nay, thị trường mạng xã hội toàn cầu đã có nhiều nền tảng nổi tiếng như Facebook, Instagram, Twitter và TikTok với hàng tỷ người dùng. Tuy nhiên, phần lớn các nền tảng này được phát triển bởi các công ty nước ngoài, trong khi thị trường nội địa vẫn còn nhiều tiềm năng chưa được khai thác đúng mức. Mặc dù đã có một số ứng dụng mạng xã hội nội địa như Zalo và Lotus, nhưng vẫn chưa thực sự cạnh tranh được với các nền tảng quốc tế về mặt tính năng và trải nghiệm người dùng. Chính vì vậy, việc nghiên cứu và phát triển một ứng dụng mạng xã hội mới, có tính thực tiễn cao và phù hợp với nhu cầu đặc thù của người dùng Việt Nam là một hướng đi cần thiết và đầy tiềm năng.

## 2. Mục tiêu nghiên cứu

Mục tiêu chính của đề tài là thiết kế và phát triển một ứng dụng mạng xã hội đa nền tảng di động với giao diện trực quan, tốc độ phản hồi nhanh, và khả năng kết nối liền mạch giữa người dùng. Ứng dụng được xây dựng với trọng tâm là tạo ra trải nghiệm người dùng tối ưu, đảm bảo tính bảo mật cao, và tích hợp các công nghệ hiện đại phù hợp với xu hướng phát triển của thị trường.

Để đạt được mục tiêu tổng thể, đề tài hướng đến các mục tiêu cụ thể sau:

* Xây dựng hệ thống xác thực người dùng đa phương thức, bao gồm đăng ký tài khoản, đăng nhập an toàn và quản lý phiên làm việc hiệu quả.

* Phát triển chức năng tạo và chia sẻ nội dung đa phương tiện như bài viết văn bản, hình ảnh, video kèm theo các tương tác cơ bản (bình luận, yêu thích, chia sẻ).

* Thiết kế và triển khai hệ thống thông báo thời gian thực, giúp người dùng cập nhật kịp thời các hoạt động liên quan đến tài khoản và mạng lưới của họ.

* Phát triển tính năng nhắn tin cá nhân và nhóm với giao diện thân thiện, hỗ trợ gửi văn bản, hình ảnh và các loại tệp đa phương tiện khác.

* Ứng dụng framework Flutter để xây dựng ứng dụng đa nền tảng, đảm bảo hoạt động mượt mà trên cả hệ điều hành Android và iOS từ một codebase duy nhất, tối ưu hóa thời gian và chi phí phát triển.

* Tích hợp Firebase Firestore làm cơ sở dữ liệu thời gian thực, cho phép đồng bộ hóa dữ liệu tức thì giữa các thiết bị và hỗ trợ khả năng mở rộng hệ thống khi số lượng người dùng tăng lên.

* Áp dụng nguyên tắc Clean Architecture trong thiết kế phần mềm để phân tách rõ ràng các tầng dữ liệu, logic nghiệp vụ và giao diện, tạo điều kiện thuận lợi cho việc bảo trì và phát triển ứng dụng trong tương lai.

* Nghiên cứu và áp dụng các nguyên tắc thiết kế trải nghiệm người dùng (UX/UI) hiện đại, đảm bảo giao diện trực quan, dễ sử dụng và phù hợp với các kích thước màn hình khác nhau.

* Tăng cường bảo mật thông tin người dùng thông qua việc triển khai Firebase Authentication, mã hóa dữ liệu nhạy cảm và áp dụng các biện pháp bảo vệ quyền riêng tư.

Thông qua việc thực hiện các mục tiêu này, đề tài hướng đến việc tạo ra một ứng dụng mạng xã hội không chỉ đáp ứng nhu cầu kết nối cơ bản mà còn mang đến trải nghiệm người dùng vượt trội, phù hợp với thói quen sử dụng và đặc thù văn hóa của người dùng Việt Nam.

Về lâu dài, đề tài cũng đặt ra mục tiêu mở rộng bao gồm việc phát triển các tính năng nâng cao như livestream, tích hợp trí tuệ nhân tạo để phân tích hành vi người dùng, cải thiện khả năng xử lý lượng lớn người dùng đồng thời, và tối ưu hóa hiệu suất ứng dụng trên các nền tảng di động khác nhau.

## 3. Phạm vi nghiên cứu

Phạm vi nghiên cứu của đề tài được giới hạn trong các lĩnh vực công nghệ sau:

* Phát triển ứng dụng di động đa nền tảng sử dụng framework Flutter, tận dụng ưu điểm của ngôn ngữ Dart và khả năng xây dựng giao diện linh hoạt.

* Thiết kế và triển khai cơ sở dữ liệu thời gian thực với Firebase Firestore, bao gồm cấu trúc dữ liệu, quy tắc bảo mật và chiến lược đồng bộ hóa.

* Nghiên cứu và áp dụng các nguyên tắc thiết kế giao diện người dùng (UI/UX) phù hợp với xu hướng hiện đại và thói quen sử dụng của người dùng Việt Nam.

* Triển khai các cơ chế bảo mật và xác thực người dùng thông qua Firebase Authentication và các biện pháp mã hóa dữ liệu.

Trong thời gian thực hiện đề tài, nghiên cứu sẽ tập trung vào việc phát triển các tính năng cơ bản của một mạng xã hội, chưa bao gồm các tính năng phức tạp như livestream, trí tuệ nhân tạo phân tích nội dung, hay hệ thống xử lý video streaming. Ứng dụng sẽ được thử nghiệm với một nhóm người dùng có quy mô nhỏ để đánh giá trải nghiệm và thu thập phản hồi trước khi tiến hành mở rộng và phát triển thêm các tính năng nâng cao.

Nội dung nghiên cứu sẽ tập trung vào các chức năng thiết yếu của một mạng xã hội như đăng ký, đăng nhập, đăng bài, tương tác, nhắn tin và thông báo, chưa bao gồm các tính năng như video streaming thời gian thực, đề xuất nội dung thông minh dựa trên AI, hay tích hợp đa ngôn ngữ.

## 5. Cấu trúc đồ án

Đồ án được tổ chức theo cấu trúc sau:

### Phần mở đầu
- Mục lục
- Danh mục các hình vẽ và bảng biểu
- Danh mục các từ viết tắt
- Tóm tắt nội dung đồ án tốt nghiệp
- Lời cảm ơn

### Nội dung chính
- **Mở đầu**: Giới thiệu tổng quan về đề tài, mục tiêu, phạm vi nghiên cứu, phương pháp thực hiện và ý nghĩa của đề tài.

- **Chương 1: Cơ sở lý thuyết**
  - Các khái niệm cơ bản liên quan đến mạng xã hội
  - Công nghệ và ngôn ngữ lập trình sử dụng (Flutter, Dart)
  - Các framework và thư viện được áp dụng (Firebase)
  - Các nguyên tắc thiết kế và kiến trúc phần mềm

- **Chương 2: Phân tích và thiết kế hệ thống**
  - Phân tích yêu cầu chức năng và phi chức năng
  - Mô hình hóa hệ thống với các sơ đồ UML
  - Thiết kế giao diện người dùng
  - Thiết kế cơ sở dữ liệu

- **Chương 3: Kết quả cài đặt và thử nghiệm**
  - Môi trường phát triển và triển khai
  - Các chức năng đã thực hiện
  - Kết quả kiểm thử và đánh giá hiệu năng
  - So sánh với mục tiêu ban đầu

### Phần kết thúc
- **Kết luận và hướng phát triển**: Tổng kết kết quả đạt được, hạn chế và đề xuất hướng phát triển tiếp theo.
- **Tài liệu tham khảo**: Danh sách các nguồn tài liệu đã tham khảo.
- **Phụ lục**: Mã nguồn, tài liệu bổ sung và các nội dung liên quan khác.

# Viết lại phần mạng xã hội

## 1.1 Các khái niệm liên quan đến đề tài

### a. Mạng xã hội

Mạng xã hội có thể được định nghĩa là các nền tảng trực tuyến cho phép người sử dụng thiết lập kết nối, chia sẻ thông tin và tương tác với nhau trong không gian số [1]. Theo thống kê gần đây, có khoảng 4,9 tỷ người (chiếm 62% dân số toàn cầu) đang sử dụng ít nhất một nền tảng mạng xã hội. Các nền tảng này đã phát triển từ những công cụ giao tiếp đơn giản thành các hệ sinh thái số phức tạp, hỗ trợ đa dạng hoạt động như chia sẻ thông tin, xây dựng cộng đồng, thương mại điện tử, và phát triển kinh doanh.

Các nền tảng mạng xã hội hiện nay thường có những đặc trưng cơ bản như: khả năng cá nhân hóa trải nghiệm, tương tác hai chiều, nội dung do người dùng tạo ra, thuật toán gợi ý cá nhân hóa, tính năng tương tác đa dạng (bình luận, chia sẻ, thích), hệ thống quản lý quyền riêng tư, thông báo thời gian thực và các công cụ phân tích dữ liệu thông minh [2].

Mạng xã hội mang lại nhiều giá trị tích cực cho xã hội như: kết nối con người vượt qua rào cản địa lý, dân chủ hóa việc tiếp cận và chia sẻ thông tin, tạo cơ hội phát triển kinh tế mới, thúc đẩy sáng tạo và giao lưu văn hóa. Tuy nhiên, cũng cần nhận thức về những thách thức đi kèm như: lan truyền thông tin sai lệch, ảnh hưởng tiêu cực đến sức khỏe tâm thần, phân cực xã hội và gia tăng hành vi tiêu cực trực tuyến.

Xu hướng phát triển đáng chú ý của mạng xã hội hiện nay bao gồm: nội dung ngắn và trực quan (như TikTok, Instagram Reels), tích hợp công nghệ thực tế ảo và thực tế tăng cường hướng tới metaverse, thương mại xã hội, tăng cường bảo mật dữ liệu cá nhân, nội dung tạm thời (Stories) và khả năng chuyển đổi liền mạch giữa các nền tảng [1][3]. Mạng xã hội đang dần chuyển đổi từ mô hình chia sẻ thông tin đơn thuần sang các hệ sinh thái kỹ thuật số toàn diện, tích hợp nhiều khía cạnh của cuộc sống hàng ngày.

### b. Phát triển ứng dụng di động

Trong lĩnh vực phát triển ứng dụng di động, có nhiều phương pháp tiếp cận khác nhau, mỗi phương pháp đều có những ưu điểm và hạn chế riêng:

* **Ứng dụng web di động**: Là giải pháp phát triển dựa trên nền tảng web được tối ưu hóa cho thiết bị di động. Phương pháp này cho phép triển khai nhanh chóng với chi phí thấp, nhưng thường có giới hạn về khả năng truy cập tính năng phần cứng và phụ thuộc vào kết nối internet.

* **Ứng dụng đa nền tảng**: Sử dụng các công nghệ như Flutter hoặc React Native để phát triển một codebase duy nhất có thể triển khai trên nhiều hệ điều hành. Cách tiếp cận này cân bằng giữa hiệu suất và chi phí phát triển, đồng thời rút ngắn thời gian đưa sản phẩm ra thị trường.

Quy trình phát triển ứng dụng di động hiện đại thường bao gồm nhiều giai đoạn có tính hệ thống: nghiên cứu thị trường và phân tích nhu cầu người dùng, lập kế hoạch chi tiết, thiết kế trải nghiệm và giao diện người dùng, lập trình và phát triển (thường áp dụng phương pháp Agile), kiểm thử đa nền tảng và đa thiết bị, triển khai lên các cửa hàng ứng dụng, và duy trì cập nhật liên tục [7] [8].

Xu hướng phát triển nổi bật trong lĩnh vực này bao gồm: ứng dụng công nghệ 5G để nâng cao trải nghiệm tương tác, tích hợp trí tuệ nhân tạo và học máy để cá nhân hóa nội dung, kết nối với hệ sinh thái Internet vạn vật (IoT), ứng dụng công nghệ thực tế ảo/thực tế tăng cường để tạo trải nghiệm tương tác mới, phát triển ứng dụng tức thời (Instant Apps) không cần cài đặt, tăng cường bảo mật dữ liệu người dùng, và xu hướng phát triển Super App tích hợp nhiều dịch vụ khác nhau trong một ứng dụng duy nhất [9] [4] [10].

### c. Kiến trúc FeatureFirst

Kiến trúc FeatureFirst là một phương pháp tổ chức mã nguồn trong phát triển ứng dụng, đặc biệt phổ biến trong các dự án Flutter. Khác với cách tiếp cận truyền thống là tổ chức mã nguồn theo loại thành phần (layerfirst), kiến trúc FeatureFirst tổ chức mã nguồn theo các tính năng hoặc module chức năng của ứng dụng [11]. Mỗi tính năng được đóng gói trong một thư mục riêng biệt, chứa tất cả các thành phần cần thiết để triển khai tính năng đó, bao gồm UI, logic nghiệp vụ, quản lý trạng thái và truy cập dữ liệu.

Trong một ứng dụng Flutter sử dụng kiến trúc FeatureFirst, cấu trúc thư mục thường được tổ chức như sau:

```
lib/
  ├── features/
  │   ├── authentication/
  │   │   ├── models/
  │   │   ├── providers/
  │   │   ├── presentation/
  │   │   ├── repository/
  │   │   └── authentication.dart
  │   ├── posts/
  │   │   ├── models/
  │   │   ├── screens/
  │   │   ├── widgets/
  │   │   └── posts.dart
  │   └── friends/
  │       ├── providers/
  │       ├── repositories/
  │       └── friends.dart
  ├── core/
  │   ├── services/
  │   ├── providers/
  │   └── core.dart
  └── main.dart
```

Mỗi module tính năng thường được tổ chức thành các thành phần sau:

1. **Models**: Chứa các lớp đại diện cho cấu trúc dữ liệu của tính năng.
2. **Providers/Repositories**: Quản lý trạng thái và xử lý logic nghiệp vụ, cũng như giao tiếp với các nguồn dữ liệu.
3. **Presentation**: Chứa các màn hình và widget UI liên quan đến tính năng.
4. **File barrel**: Mỗi tính năng thường có một file "barrel" (như authentication.dart) để xuất các thành phần cần thiết, giúp đơn giản hóa việc import.

Ngoài ra, thư mục `core` chứa các thành phần dùng chung giữa các tính năng như tiện ích, dịch vụ, và cấu hình chung của ứng dụng.

Kiến trúc FeatureFirst mang lại nhiều lợi ích trong quá trình phát triển ứng dụng:

1. **Tính mô-đun hóa cao**: Mỗi tính năng được đóng gói độc lập, giúp dễ dàng thêm, sửa đổi hoặc loại bỏ tính năng mà không ảnh hưởng đến các phần khác của ứng dụng.

2. **Phát triển song song hiệu quả**: Các nhóm phát triển khác nhau có thể làm việc trên các tính năng riêng biệt mà không gây xung đột.

3. **Khả năng tái sử dụng**: Các tính năng có thể được tái sử dụng trong các dự án khác nhau với ít sự thay đổi.

4. **Dễ dàng kiểm thử**: Mỗi tính năng có thể được kiểm thử độc lập, giúp tăng độ tin cậy của ứng dụng.

5. **Quản lý mã nguồn hiệu quả**: Cấu trúc rõ ràng giúp các nhà phát triển dễ dàng tìm kiếm và hiểu mã nguồn, đặc biệt trong các dự án lớn.

Tuy nhiên, kiến trúc này cũng có một số thách thức như việc xác định ranh giới giữa các tính năng, quản lý sự phụ thuộc giữa các module, và đảm bảo tính nhất quán trong thiết kế. Để khắc phục những thách thức này, các dự án thường kết hợp kiến trúc FeatureFirst với các nguyên tắc thiết kế khác như Clean Architecture hoặc SOLID để tạo ra một cấu trúc ứng dụng vừa linh hoạt vừa dễ bảo trì [12].

Trong ứng dụng mạng xã hội của đề tài này, kiến trúc FeatureFirst được áp dụng để tổ chức mã nguồn thành các module chức năng như xác thực (authentication), bài viết (posts), tin nhắn (messages), thông báo (notifications), và quản lý bạn bè (friends). Mỗi module chứa đầy đủ các thành phần cần thiết để hoạt động độc lập, đồng thời có thể tương tác với các module khác thông qua các giao diện được định nghĩa rõ ràng. 