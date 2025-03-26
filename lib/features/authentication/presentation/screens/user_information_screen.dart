import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../../../core/core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/get_user_info_as_stream_provider.dart';
import '../../../../core/widgets/pickers/gender_picker.dart';
import '../../../../core/widgets/pickers/birthday_picker.dart';

/// Màn hình cho phép người dùng hoàn thiện hoặc cập nhật thông tin cá nhân.
///
/// Màn hình này bao gồm các chức năng:
/// - Cập nhật ảnh đại diện
/// - Nhập thông tin cá nhân (họ tên, giới tính, ngày sinh)
/// - Nhập thông tin liên hệ (số điện thoại, địa chỉ)
/// - Nhập tiểu sử cá nhân
class UserInformationScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.userInformation;

  final bool isEditing;
  final Map<String, dynamic>? arguments;

  const UserInformationScreen({
    super.key,
    this.isEditing = false,
    this.arguments,
  });

  @override
  ConsumerState<UserInformationScreen> createState() =>
      _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  /// Form key để quản lý và validate form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controller để quản lý các trường nhập liệu
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  /// Các biến lưu trữ thông tin người dùng chọn
  DateTime? _selectedDate;
  String? _selectedGender;
  File? _selectedImage;
  late final String _uid;
  late final String _email;
  String? _profileImageUrl;

  /// Biến quản lý trạng thái loading và lỗi
  bool _isLoading = false;
  String? _error;

  final ImagePickerHelper _imagePicker = ImagePickerHelper();

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      // Lấy thông tin từ màn hình đăng ký
      _uid = widget.arguments?['uid'] as String;
      _email = widget.arguments?['email'] as String;
    }
    // Nếu đang edit, lấy thông tin từ stream
    ref.read(getUserInfoAsStreamProvider).whenData((user) {
      if (mounted && widget.isEditing) {
        _updateFormWithUserData(user);
      }
    });
  }

  void _updateFormWithUserData(UserModel user) {
    setState(() {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _bioController.text = user.decs ?? '';
      _selectedDate = user.birthDay;
      _selectedGender = user.gender;
      _uid = user.uid;
      _email = user.email;
      _profileImageUrl = user.profileImage;
    });
  }

  /// Xử lý việc hoàn thiện/cập nhật thông tin người dùng
  ///
  /// Quy trình xử lý:
  /// 1. Kiểm tra validate form
  /// 2. Kiểm tra các trường bắt buộc (ngày sinh, giới tính)
  /// 3. Cập nhật thông tin vào model
  /// 4. Lưu thông tin lên Firestore
  /// 5. Xử lý phản hồi thành công/thất bại
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      showToastMessage(text: 'validations.birthday.required'.tr());
      return;
    }

    if (_selectedGender == null) {
      showToastMessage(text: 'validations.gender.required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepository = ref.read(authProvider);
      final updatedUser = widget.isEditing
          ? await authRepository.updateUserProfile(
              uid: _uid,
              fullName: _fullNameController.text.trim(),
              gender: _selectedGender!,
              birthDay: _selectedDate!,
              phoneNumber: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              desc: _bioController.text.trim(),
              profileImage: _selectedImage,
            )
          : await authRepository.completeUserProfile(
              uid: _uid,
              fullName: _fullNameController.text.trim(),
              gender: _selectedGender!,
              birthDay: _selectedDate!,
              phoneNumber: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              desc: _bioController.text.trim(),
              profileImage: _selectedImage,
            );

      if (!mounted) return;

      // Chỉ cập nhật URL ảnh nếu có ảnh mới
      if (_selectedImage != null) {
        setState(() {
          _profileImageUrl = updatedUser.profileImage;
          _selectedImage = null; // Reset ảnh đã chọn
        });
      }

      showToastMessage(text: 'profile.update.success'.tr());
      if (widget.isEditing) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider).logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteConstants.login,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    }
  }

  /// Xây dựng giao diện màn hình
  ///
  /// Cấu trúc giao diện:
  /// - AppBar với tiêu đề
  /// - Form chứa các trường thông tin
  /// - Ảnh đại diện có thể chỉnh sửa
  /// - Các trường nhập liệu thông tin cá nhân
  /// - Nút submit để lưu thông tin
  @override
  Widget build(BuildContext context) {
    final userStream = widget.isEditing
        ? ref.watch(getUserInfoAsStreamProvider)
        : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'profile.edit.title'.tr()
              : 'profile.complete.title'.tr(),
        ),
        centerTitle: true,
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: userStream.when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: DisplayUserImage(
                    finalFileImage: _selectedImage,
                    imageUrl: _profileImageUrl,
                    userName: _fullNameController.text,
                    radius: 60,
                    showEditIcon: true,
                    onPressed: () {
                      _imagePicker.showImagePickerBottomSheet(
                        context: context,
                        onSuccess: () {
                          setState(() {
                            _selectedImage = _imagePicker.finalFileImage;
                            _profileImageUrl = null; // Xóa URL khi có ảnh mới
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _email,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 20),
                RoundTextField(
                  controller: _fullNameController,
                  labelText: 'fields.full_name.label'.tr(),
                  validator: ValidationUtils.validateName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 45,
                      child: GenderPicker(
                        selectedGender: _selectedGender,
                        onChanged: (value) => setState(() {
                          _selectedGender = value;
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 55,
                      child: BirthdayPicker(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) => setState(() {
                          _selectedDate = date;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RoundTextField(
                  controller: _phoneController,
                  labelText: 'fields.phone.label'.tr(),
                  validator: ValidationUtils.validatePhone,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                RoundTextField(
                  controller: _addressController,
                  labelText: 'fields.address.label'.tr(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                RoundTextField(
                  controller: _bioController,
                  labelText: 'fields.bio.label'.tr(),
                  maxLines: 3,
                  maxLength: 150,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                RoundButtonFill(
                  onPressed: !_isLoading ? _handleSubmit : null,
                  label: _isLoading
                      ? 'profile.update.processing'.tr()
                      : widget.isEditing
                          ? 'profile.update.save'.tr()
                          : 'profile.complete.submit'.tr(),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
        loading: () => widget.isEditing
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.shrink(),
        error: (error, stack) => widget.isEditing
            ? Center(child: Text(error.toString()))
            : const SizedBox.shrink(),
      ),
    );
  }

  /// Giải phóng tài nguyên khi widget bị hủy
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
