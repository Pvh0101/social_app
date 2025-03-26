/// Module xác thực và quản lý người dùng.
///
/// Module này cung cấp các thành phần cần thiết để xử lý:
/// - Đăng nhập và đăng ký tài khoản
/// - Xác minh email
/// - Quản lý thông tin người dùng
/// - Theo dõi trạng thái xác thực
///
/// Sử dụng Firebase Authentication và Firestore làm backend.

// Models
export 'models/user_model.dart';

// Providers
export 'providers/auth_provider.dart';
export 'providers/auth_state_provider.dart';
export 'providers/get_user_info_provider.dart';
export 'providers/get_user_info_by_id_provider.dart';
export 'providers/get_user_info_as_stream_provider.dart';
export 'providers/get_user_info_as_stream_by_id_provider.dart';

// Screens
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';
export 'presentation/screens/splash_screen.dart';
export 'presentation/screens/user_information_screen.dart';
export 'presentation/screens/email_verification_screen.dart';

// Repositories
export 'repository/auth_repository.dart';
