import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../services/api_config.dart';
import '../services/app_feedback.dart';
import '../usecases/upload_usecases.dart';
import '../widgets/gradient_button.dart';
import '../widgets/luminous_background.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nickname = TextEditingController();
  final _avatar = TextEditingController();
  final _age = TextEditingController();
  final _bio = TextEditingController();
  final _tags = TextEditingController();
  final _picker = ImagePicker();

  List<String> _photos = const [];
  bool _uploading = false;

  @override
  void dispose() {
    _nickname.dispose();
    _avatar.dispose();
    _age.dispose();
    _bio.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(profileControllerProvider).valueOrNull;
    if (user != null && _nickname.text.isEmpty) {
      _nickname.text = user.nickname;
      _avatar.text = user.avatar;
      _age.text = '${user.age}';
      _bio.text = user.bio;
      _tags.text = user.tags.join(', ');
      _photos = user.photos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: LuminousBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              TextField(
                controller: _nickname,
                decoration: const InputDecoration(hintText: '昵称'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ImageTile(
                    label: '头像',
                    imageUrl: _avatar.text.trim(),
                    onTap: () => _pickAndUploadImage(isAvatar: true),
                  ),
                  ..._photos.map(
                    (photo) => _ImageTile(
                      imageUrl: photo,
                      onDelete: () => setState(() {
                        _photos =
                            _photos.where((item) => item != photo).toList();
                      }),
                    ),
                  ),
                  if (_photos.length < 6)
                    _AddImageTile(
                      loading: _uploading,
                      onTap: () => _pickAndUploadImage(isAvatar: false),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '年龄'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bio,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '个人简介'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(hintText: '标签，使用逗号分隔'),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: _uploading ? '上传中...' : '保存修改',
                icon: Icons.check_rounded,
                onPressed: profile == null || _uploading
                    ? null
                    : () async {
                        final updated = AppUser(
                          id: profile.id,
                          email: profile.email,
                          nickname: _nickname.text.trim(),
                          avatar: _avatar.text.trim(),
                          photos: _photos,
                          age: int.tryParse(_age.text.trim()) ?? profile.age,
                          bio: _bio.text.trim(),
                          tags: _tags.text
                              .split(',')
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList(),
                          lat: profile.lat,
                          lng: profile.lng,
                          onlineStatus: profile.onlineStatus,
                          distanceKm: profile.distanceKm,
                        );
                        await ref
                            .read(profileControllerProvider.notifier)
                            .save(updated);
                        if (context.mounted) {
                          AppFeedback.showToast('资料已更新');
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage({required bool isAvatar}) async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null || _uploading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('打开相机'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final rawUrl = await ref.read(uploadImageUseCaseProvider).call(
            token: session.token,
            file: picked,
          );
      final uploadedUrl =
          rawUrl.startsWith('http') ? rawUrl : '${ApiConfig.baseUrl}$rawUrl';
      setState(() {
        if (isAvatar) {
          _avatar.text = uploadedUrl;
        } else {
          _photos = [..._photos, uploadedUrl];
        }
      });
      AppFeedback.showToast(isAvatar ? '头像上传成功' : '照片上传成功');
    } catch (error) {
      AppFeedback.showError('上传失败：$error');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    this.label,
    required this.imageUrl,
    this.onTap,
    this.onDelete,
  });

  final String? label;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.06),
              image: imageUrl.trim().isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
            ),
            child: imageUrl.trim().isEmpty
                ? Center(child: Text(label ?? '上传'))
                : null,
          ),
          if (label != null)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label!, style: const TextStyle(fontSize: 12)),
              ),
            ),
          if (onDelete != null)
            Positioned(
              right: 6,
              top: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
        ),
      ),
    );
  }
}
