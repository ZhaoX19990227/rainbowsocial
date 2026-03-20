import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
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
                  decoration: const InputDecoration(hintText: '昵称')),
              const SizedBox(height: 14),
              TextField(
                  controller: _avatar,
                  decoration: const InputDecoration(hintText: '头像地址')),
              const SizedBox(height: 14),
              TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '年龄')),
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
                label: '保存修改',
                icon: Icons.check_rounded,
                onPressed: profile == null
                    ? null
                    : () async {
                        final updated = AppUser(
                          id: profile.id,
                          email: profile.email,
                          nickname: _nickname.text.trim(),
                          avatar: _avatar.text.trim(),
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
}
