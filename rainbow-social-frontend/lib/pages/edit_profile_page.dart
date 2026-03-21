import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../services/api_config.dart';
import '../services/app_feedback.dart';
import '../services/tag_options.dart';
import '../services/zodiac_utils.dart';
import '../usecases/upload_usecases.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/luminous_background.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  static const _maxTags = 5;

  final _nickname = TextEditingController();
  final _avatar = TextEditingController();
  final _age = TextEditingController();
  final _heightCm = TextEditingController();
  final _weightKg = TextEditingController();
  final _birthday = TextEditingController();
  final _bio = TextEditingController();
  final _tags = TextEditingController();
  final _picker = ImagePicker();

  List<String> _photos = const [];
  List<String> _selectedTags = const [];
  bool _uploading = false;

  @override
  void dispose() {
    _nickname.dispose();
    _avatar.dispose();
    _age.dispose();
    _heightCm.dispose();
    _weightKg.dispose();
    _birthday.dispose();
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
      _heightCm.text = '${user.heightCm}';
      _weightKg.text = '${user.weightKg}';
      _birthday.text = user.birthday;
      _bio.text = user.bio;
      _tags.text = user.tags.join(', ');
      _selectedTags = [...user.tags];
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightCm,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '身高(cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightKg,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '体重(kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _birthday,
                readOnly: true,
                onTap: _pickBirthday,
                decoration: InputDecoration(
                  hintText: '生日',
                  suffixIcon: _birthday.text.trim().isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              ZodiacUtils.displayName(
                                ZodiacUtils.zodiacFromBirthday(
                                      ZodiacUtils.tryParseBirthday(
                                        _birthday.text.trim(),
                                      ),
                                    ) ??
                                    '',
                              ),
                            ),
                          ),
                        ),
                ),
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
                decoration:
                    const InputDecoration(hintText: '标签，使用逗号分隔，最多 5 个'),
                onChanged: _syncTagsFromInput,
              ),
              const SizedBox(height: 8),
              Text(
                '已选择 ${_selectedTags.length}/$_maxTags',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('可选标签', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profileTagOptions.map((tag) {
                        return FilterChip(
                          selected: _selectedTags.contains(tag),
                          label: Text(tag),
                          onSelected: (_) => _toggleTag(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                          heightCm: int.tryParse(_heightCm.text.trim()) ??
                              profile.heightCm,
                          weightKg: int.tryParse(_weightKg.text.trim()) ??
                              profile.weightKg,
                          birthday: _birthday.text.trim(),
                          zodiacSign: ZodiacUtils.zodiacFromBirthday(
                                ZodiacUtils.tryParseBirthday(_birthday.text.trim()),
                              ) ??
                              '',
                          mbtiType: profile.mbtiType,
                          bio: _bio.text.trim(),
                          tags: _parseTags(_tags.text),
                          lat: profile.lat,
                          lng: profile.lng,
                          locationLabel: profile.locationLabel,
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

  Future<void> _pickBirthday() async {
    final existing = ZodiacUtils.tryParseBirthday(_birthday.text.trim());
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime(now.year - 24, now.month, now.day),
      firstDate: DateTime(1960, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _birthday.text = ZodiacUtils.formatBirthday(picked);
    });
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

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags = _selectedTags.where((item) => item != tag).toList();
      } else if (_selectedTags.length < _maxTags) {
        _selectedTags = [..._selectedTags, tag];
      } else {
        AppFeedback.showToast('最多选择 $_maxTags 个标签');
      }
      _tags.text = _selectedTags.join(', ');
    });
  }

  void _syncTagsFromInput(String value) {
    final parsed = _parseTags(value);
    final trimmed = parsed.take(_maxTags).toList();
    if (parsed.length > _maxTags) {
      AppFeedback.showToast('最多选择 $_maxTags 个标签');
    }
    setState(() {
      _selectedTags = trimmed;
      if (_tags.text != trimmed.join(', ')) {
        _tags.value = TextEditingValue(
          text: trimmed.join(', '),
          selection: TextSelection.collapsed(
            offset: trimmed.join(', ').length,
          ),
        );
      }
    });
  }

  List<String> _parseTags(String value) {
    final result = <String>[];
    final seen = <String>{};
    for (final raw in value.split(',')) {
      final tag = raw.trim();
      if (tag.isEmpty || seen.contains(tag)) {
        continue;
      }
      seen.add(tag);
      result.add(tag);
    }
    return result;
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
