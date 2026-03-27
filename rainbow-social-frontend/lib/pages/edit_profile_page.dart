import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../routes/app_router.dart';
import '../services/api_config.dart';
import '../services/app_feedback.dart';
import '../services/profile_completion.dart';
import '../services/tag_options.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../usecases/upload_usecases.dart';
import '../usecases/user_usecases.dart';
import '../widgets/glass_card.dart';
import '../widgets/inline_birthday_picker.dart';
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
  String _selectedPositionRole = '';
  String _locationLabel = '';
  double _lat = 0;
  double _lng = 0;
  bool _uploading = false;
  bool _updatingLocation = false;
  int? _hydratedUserId;

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
    final sessionUser = ref.read(authControllerProvider).valueOrNull?.user;
    final user = ref.read(profileControllerProvider).valueOrNull ?? sessionUser;
    if (user != null && _hydratedUserId != user.id) {
      _hydrateFromUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = ref.watch(authControllerProvider).valueOrNull?.user;
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ?? sessionUser;
    final isOnboardingFlow = ProfileCompletion.needsOnboarding(profile);
    final missingFields = ProfileCompletion.missingFields(profile);
    final zodiacSign = ZodiacUtils.zodiacFromBirthday(
          ZodiacUtils.tryParseBirthday(_birthday.text.trim()),
        ) ??
        '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(isOnboardingFlow ? '完善资料' : '编辑资料'),
        actions: [
          TextButton(
            onPressed: profile == null || _uploading
                ? null
                : () => _saveProfile(profile, isOnboardingFlow),
            child: Text(_uploading ? '上传中...' : '保存'),
          ),
        ],
      ),
      body: PopScope(
        canPop: true,
        child: LuminousBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (isOnboardingFlow) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF7E9FF),
                          Color(0xFFE8F3FF),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '先把关键资料补完整',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '完成这些信息后，我们才能更准确地展示推荐、附近和个人中心。',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: missingFields
                              .map(
                                (field) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                  child: Text(
                                    field,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionHeader(
                  title: '展示资料',
                  subtitle: '长按下方照片可调整顺序',
                  trailing: IconButton(
                    onPressed: _uploading
                        ? null
                        : () => _pickAndUploadImage(isAvatar: false),
                    icon: const Icon(Icons.add_a_photo_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _PhotoGridCard(
                  avatarUrl: _avatar.text.trim(),
                  photos: _normalizePhotos(
                    _photos,
                    avatarUrl: _avatar.text.trim(),
                  ),
                  uploading: _uploading,
                  onAvatarTap: () => _pickAndUploadImage(isAvatar: true),
                  onAddTap: () => _pickAndUploadImage(isAvatar: false),
                  onReorderPhotos: _reorderPhotos,
                  onDeletePhoto: (photo) => setState(() {
                    _photos = _normalizePhotos(
                      _photos.where((item) => item != photo).toList(),
                      avatarUrl: _avatar.text.trim(),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                const _SectionHeader(title: '基础信息'),
                const SizedBox(height: 14),
                GlassCard(
                  borderRadius: BorderRadius.circular(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: '昵称',
                        child: TextField(
                          controller: _nickname,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: const InputDecoration(hintText: '输入你的昵称'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: '年龄',
                              child: TextField(
                                controller: _age,
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration:
                                    const InputDecoration(hintText: '26'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: '身高 (CM)',
                              child: TextField(
                                controller: _heightCm,
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration:
                                    const InputDecoration(hintText: '182'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: '体重 (KG)',
                              child: TextField(
                                controller: _weightKg,
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration:
                                    const InputDecoration(hintText: '75'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: '城市 / 位置',
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  color: AppTheme.surfaceHighest,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _locationLabel.trim().isNotEmpty
                                            ? _locationLabel.trim()
                                            : '点击右侧按钮获取当前位置',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _updatingLocation
                                          ? null
                                          : _resolveCurrentLocation,
                                      icon: _updatingLocation
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                              color: AppTheme.primary,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: '生日',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InlineBirthdayPicker(
                              initialDate: ZodiacUtils.tryParseBirthday(
                                    _birthday.text.trim(),
                                  ) ??
                                  DateTime(1998, 6, 15),
                              onChanged: (value) {
                                setState(() {
                                  _birthday.text =
                                      ZodiacUtils.formatBirthday(value);
                                });
                              },
                            ),
                            if (zodiacSign.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: const Color(0xFFFFE2F1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: AppTheme.tertiary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      ZodiacUtils.displayName(zodiacSign),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppTheme.tertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionHeader(title: '身份档案'),
                const SizedBox(height: 14),
                GlassCard(
                  borderRadius: BorderRadius.circular(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: '人格类型 (MBTI)',
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: const Color(0x1FD2E4FF),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.secondary,
                                ),
                                child: Center(
                                  child: Text(
                                    profile?.mbtiType.trim().isEmpty ?? true
                                        ? 'MB'
                                        : profile!.mbtiType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?.mbtiType.trim().isEmpty ?? true
                                          ? '还没有人格结果'
                                          : profile!.mbtiType,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile?.mbtiType.trim().isEmpty ?? true
                                          ? '完成测试后，会展示你的人格类型'
                                          : '热情、有创意、自由的精神',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(AppRouter.mbtiTest),
                                child: const Text('去测试'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: '属性',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: profilePositionOptions.map((option) {
                            final selected = _selectedPositionRole == option;
                            return ChoiceChip(
                              selected: selected,
                              label: Text(option),
                              onSelected: (_) {
                                setState(() => _selectedPositionRole = option);
                              },
                              selectedColor:
                                  AppTheme.primary.withValues(alpha: 0.16),
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.ghostBorder,
                              ),
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: '个性标签',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _tags,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: const InputDecoration(
                                hintText: '标签，使用逗号分隔，最多 5 个',
                              ),
                              onChanged: _syncTagsFromInput,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '已选择 ${_selectedTags.length}/$_maxTags',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
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
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: '简介',
                        child: TextField(
                          controller: _bio,
                          maxLines: 4,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            hintText: '介绍一下你自己，让更多人认识你...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(AppUser profile, bool isOnboardingFlow) async {
    final updated = AppUser(
      id: profile.id,
      email: profile.email,
      nickname: _nickname.text.trim(),
      avatar: _avatar.text.trim(),
      photos: _normalizePhotos(
        _photos,
        avatarUrl: _avatar.text.trim(),
      ),
      age: int.tryParse(_age.text.trim()) ?? profile.age,
      heightCm: int.tryParse(_heightCm.text.trim()) ?? profile.heightCm,
      weightKg: int.tryParse(_weightKg.text.trim()) ?? profile.weightKg,
      birthday: _birthday.text.trim(),
      zodiacSign: ZodiacUtils.zodiacFromBirthday(
            ZodiacUtils.tryParseBirthday(_birthday.text.trim()),
          ) ??
          '',
      mbtiType: profile.mbtiType,
      bio: _bio.text.trim(),
      tags: _parseTags(_tags.text),
      positionRole: _selectedPositionRole.trim(),
      lat: _lat,
      lng: _lng,
      locationLabel: _locationLabel.trim(),
      onlineStatus: profile.onlineStatus,
      distanceKm: profile.distanceKm,
    );
    await ref.read(profileControllerProvider.notifier).save(updated);
    if (!mounted) return;
    AppFeedback.showToast(isOnboardingFlow ? '资料已保存' : '资料已更新');
    if (isOnboardingFlow) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.main,
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _resolveCurrentLocation() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null || _updatingLocation) return;

    setState(() => _updatingLocation = true);
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentPosition();
      final locationLabel =
          await ref.read(locationLabelServiceProvider).getLocationLabel(
                lat: position.latitude,
                lng: position.longitude,
              );
      final updated = await ref.read(updateLocationUseCaseProvider)(
        session.token,
        lat: position.latitude,
        lng: position.longitude,
        locationLabel: locationLabel,
      );
      ref.read(authControllerProvider.notifier).updateSessionUser(updated);
      ref.read(profileControllerProvider.notifier).load();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationLabel = updated.locationLabel.trim().isEmpty
            ? locationLabel
            : updated.locationLabel;
      });
    } catch (error) {
      AppFeedback.showError('位置获取失败：$error');
    } finally {
      if (mounted) {
        setState(() => _updatingLocation = false);
      }
    }
  }

  Future<void> _pickAndUploadImage({required bool isAvatar}) async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null || _uploading) return;

    final source = await AppFeedback.showJellySheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('打开相机'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
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
          _photos = _normalizePhotos(_photos, avatarUrl: uploadedUrl);
        } else {
          _photos = _normalizePhotos(
            [..._photos, uploadedUrl],
            avatarUrl: _avatar.text.trim(),
          );
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

  void _hydrateFromUser(AppUser user) {
    _hydratedUserId = user.id;
    _nickname.text = user.nickname;
    _avatar.text = user.avatar;
    _age.text = '${user.age}';
    _heightCm.text = '${user.heightCm}';
    _weightKg.text = '${user.weightKg}';
    _birthday.text = user.birthday;
    _bio.text = user.bio;
    _tags.text = user.tags.join(', ');
    _selectedTags = [...user.tags];
    _selectedPositionRole = user.positionRole;
    _locationLabel = user.locationLabel;
    _lat = user.lat;
    _lng = user.lng;
    _photos = _normalizePhotos(user.photos, avatarUrl: user.avatar);
  }

  List<String> _normalizePhotos(List<String> photos,
      {required String avatarUrl}) {
    final seen = <String>{};
    final result = <String>[];
    for (final photo in photos) {
      final normalized = photo.trim();
      if (normalized.isEmpty ||
          normalized == avatarUrl.trim() ||
          seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(normalized);
    }
    return result;
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      final updated = [
        ..._normalizePhotos(_photos, avatarUrl: _avatar.text.trim())
      ];
      if (oldIndex < 0 ||
          oldIndex >= updated.length ||
          newIndex < 0 ||
          newIndex >= updated.length) {
        return;
      }
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _photos = updated;
    });
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    this.label,
    required this.imageUrl,
    this.onTap,
    this.onDelete,
    this.large = false,
  });

  final String? label;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: large ? 214 : 98,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(large ? 22 : 999),
              color: AppTheme.surfaceHighest,
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
                  color: AppTheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
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
                    color: Colors.black.withValues(alpha: 0.36),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Colors.white),
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
        width: double.infinity,
        height: 98,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ghostBorder),
          color: AppTheme.surfaceHighest,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PhotoGridCard extends StatelessWidget {
  const _PhotoGridCard({
    required this.avatarUrl,
    required this.photos,
    required this.uploading,
    required this.onAvatarTap,
    required this.onAddTap,
    required this.onReorderPhotos,
    required this.onDeletePhoto,
  });

  final String avatarUrl;
  final List<String> photos;
  final bool uploading;
  final VoidCallback onAvatarTap;
  final VoidCallback onAddTap;
  final void Function(int oldIndex, int newIndex) onReorderPhotos;
  final ValueChanged<String> onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final extraPhotos = photos.take(5).toList();
    return GlassCard(
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _ImageTile(
                  label: '主头像',
                  imageUrl: avatarUrl,
                  onTap: onAvatarTap,
                  large: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final photo in extraPhotos.take(2)) ...[
                      _ImageTile(
                        imageUrl: photo,
                        onDelete: () => onDeletePhoto(photo),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (extraPhotos.length < 2)
                      _AddImageTile(
                        loading: uploading,
                        onTap: onAddTap,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              final photoIndex = index + 2;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: photoIndex < extraPhotos.length
                        ? _ImageTile(
                            imageUrl: extraPhotos[photoIndex],
                            onDelete: () =>
                                onDeletePhoto(extraPhotos[photoIndex]),
                          )
                        : _AddImageTile(
                            loading: uploading,
                            onTap: onAddTap,
                          ),
                  ),
                ),
              );
            }),
          ),
          if (extraPhotos.length > 1) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拖动排序',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 92,
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      itemCount: extraPhotos.length,
                      onReorder: (oldIndex, newIndex) {
                        final target =
                            oldIndex < newIndex ? newIndex - 1 : newIndex;
                        onReorderPhotos(oldIndex, target);
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            final lift = Tween<double>(begin: 1, end: 1.04)
                                .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ))
                                .value;
                            return Transform.scale(
                              scale: lift,
                              child: Material(
                                color: Colors.transparent,
                                child: child,
                              ),
                            );
                          },
                        );
                      },
                      itemBuilder: (context, index) {
                        final photo = extraPhotos[index];
                        return Container(
                          key: ValueKey(photo),
                          width: 78,
                          margin: EdgeInsets.only(
                            right: index == extraPhotos.length - 1 ? 0 : 12,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child:
                                      Image.network(photo, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                left: 6,
                                top: 6,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
