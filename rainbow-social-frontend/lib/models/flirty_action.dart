import 'package:flutter/material.dart';

enum FlirtyMoodGroup {
  tease,
  closer,
  cute,
  stir,
}

extension FlirtyMoodGroupCopy on FlirtyMoodGroup {
  String get title {
    switch (this) {
      case FlirtyMoodGroup.tease:
        return '坏一点';
      case FlirtyMoodGroup.closer:
        return '再靠近';
      case FlirtyMoodGroup.cute:
        return '软绵绵';
      case FlirtyMoodGroup.stir:
        return '撩一下';
    }
  }

  String get subtitle {
    switch (this) {
      case FlirtyMoodGroup.tease:
        return '先坏一下，再看他炸毛和脸红。';
      case FlirtyMoodGroup.closer:
        return '距离压近一点，暧昧就会自己升温。';
      case FlirtyMoodGroup.cute:
        return '软下来、慢下来，像温柔落在肩上。';
      case FlirtyMoodGroup.stir:
        return '不需要碰很多，眼神和呼吸就够了。';
    }
  }
}

class FlirtyAssetPlan {
  const FlirtyAssetPlan({
    required this.coverFrame,
    required this.previewAnimation,
    required this.fullscreenAnimation,
    required this.coverFormat,
    required this.previewFormat,
    required this.fullscreenFormat,
    required this.effectsFormat,
  });

  final String coverFrame;
  final String previewAnimation;
  final String fullscreenAnimation;
  final String coverFormat;
  final String previewFormat;
  final String fullscreenFormat;
  final String effectsFormat;
}

class FlirtyBeat {
  const FlirtyBeat({
    required this.timing,
    required this.title,
    required this.description,
  });

  final String timing;
  final String title;
  final String description;
}

class FlirtyRigSuggestion {
  const FlirtyRigSuggestion({
    required this.bones,
    required this.controllers,
    required this.notes,
  });

  final List<String> bones;
  final List<String> controllers;
  final String notes;
}

class FlirtyActionStoryboard {
  const FlirtyActionStoryboard({
    required this.coverFrame,
    required this.previewDuration,
    required this.previewBeats,
    required this.fullDuration,
    required this.fullBeats,
    required this.poseNotes,
    required this.expressionNotes,
    required this.gazeNotes,
    required this.forceNotes,
    required this.reboundNotes,
    required this.rigSuggestion,
    required this.effectLayers,
  });

  final String coverFrame;
  final String previewDuration;
  final List<FlirtyBeat> previewBeats;
  final String fullDuration;
  final List<FlirtyBeat> fullBeats;
  final String poseNotes;
  final String expressionNotes;
  final String gazeNotes;
  final String forceNotes;
  final String reboundNotes;
  final FlirtyRigSuggestion rigSuggestion;
  final List<String> effectLayers;
}

class FlirtyAction {
  const FlirtyAction({
    required this.id,
    required this.label,
    required this.preview,
    required this.icon,
    required this.gradient,
    required this.hint,
    required this.stageTitle,
    required this.stageSubtitle,
    required this.motionNotes,
    required this.hapticNotes,
    required this.moodGroup,
    required this.moodTag,
    required this.sceneMoment,
    required this.loopNotes,
    required this.assetRecommendation,
    required this.assetPlan,
    required this.storyboard,
  });

  final String id;
  final String label;
  final String preview;
  final IconData icon;
  final List<Color> gradient;
  final String hint;
  final String stageTitle;
  final String stageSubtitle;
  final String motionNotes;
  final String hapticNotes;
  final FlirtyMoodGroup moodGroup;
  final String moodTag;
  final String sceneMoment;
  final String loopNotes;
  final String assetRecommendation;
  final FlirtyAssetPlan assetPlan;
  final FlirtyActionStoryboard storyboard;

  static const all = <FlirtyAction>[
    FlirtyAction(
      id: 'poke_butt',
      label: '拍拍屁股',
      preview: '小熊坏笑着轻拍了一下你',
      icon: Icons.back_hand_rounded,
      gradient: [Color(0xFF9B63FF), Color(0xFF7CCBFF)],
      hint: '拍得很轻，反应要大，坏笑要比动作慢半拍落下来。',
      stageTitle: '坏笑轻拍',
      stageSubtitle: '小熊靠近半步，手腕轻弹一下，小猴炸毛回头，气氛瞬间从平静变成甜辣。',
      motionNotes: '蓄力要短，命中要轻，反应重点落在小猴臀线、肩线和回头节奏。',
      hapticNotes: '命中瞬间 medium impact，第二次回弹补一次 light impact。',
      moodGroup: FlirtyMoodGroup.tease,
      moodTag: 'Mischief',
      sceneMoment: '坏笑先到，拍击后到，小猴被撩得整个上半身都弹了一下。',
      loopNotes: '蓄力 15%，轻拍 10%，双回弹 45%，最后收在小猴回头瞪人的半羞恼状态。',
      assetRecommendation: '主角骨骼走 Rive，拍击星点和速度线拆成独立 sprite sheet。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '停在小熊坏笑前倾、手掌即将落下的那一帧。',
        previewAnimation: '1.3 秒：靠近、轻拍、炸毛回头。',
        fullscreenAnimation: '2.8 秒：补足臀部双回弹、肩线晃动和视线对撞。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '小熊身体偏左前压，右掌悬在小猴臀后半掌位置；小猴还没回头，耳朵放松，形成偷袭前一帧。',
        previewDuration: '1.3s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.3s',
            title: '坏笑靠近',
            description: '小熊肩线压低、头微歪、手肘收紧，小猴视线仍朝前。',
          ),
          FlirtyBeat(
            timing: '0.3s - 0.55s',
            title: '轻拍命中',
            description: '掌心快速落下，命中点偏身体外侧，不做厚重挥击。',
          ),
          FlirtyBeat(
            timing: '0.55s - 1.3s',
            title: '炸毛回头',
            description: '小猴臀线先弹、肩再弹、最后头回转，表情从懵到羞恼。',
          ),
        ],
        fullDuration: '2.8s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.35s',
            title: '蓄力试探',
            description: '小熊脚尖前送半步，重心从后脚转到前脚，坏笑慢慢抬起。',
          ),
          FlirtyBeat(
            timing: '0.35s - 0.62s',
            title: '手掌轻拍',
            description: '手腕弹出而不是整条手臂甩出，保持轻、快、俏皮。',
          ),
          FlirtyBeat(
            timing: '0.62s - 1.35s',
            title: '双段回弹',
            description: '小猴下盘弹起两次，第二次幅度更小，耳朵和发丝延迟 2 帧跟上。',
          ),
          FlirtyBeat(
            timing: '1.35s - 2.8s',
            title: '回头对视',
            description: '小猴回头炸毛，小熊仍挂着坏笑，视线正面碰上后停顿半拍。',
          ),
        ],
        poseNotes: '小熊厚实前倾，小猴身体先被动弹起再主动回头；受力点落在小猴臀后侧和腰线。',
        expressionNotes: '小熊用坏笑和半眯眼，小猴从日常切到炸毛，再落到害羞瞪视。',
        gazeNotes: '命中前小熊偷看，小猴朝前；回头时两人短暂正对视线，形成笑点。',
        forceNotes: '受力来自小熊手腕轻弹，小猴反馈以臀线夸张 bounce 和肩颈迟到反应呈现。',
        reboundNotes: '回弹采用快-慢两段阻尼，第一下大、第二下小，最终停在头部仍轻颤的余波。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'bear_root / spine / head / arm_front / arm_back / hand_front',
            'monkey_root / hip / spine / head / ear_l / ear_r / tail_stub',
          ],
          controllers: [
            '拍击命中点 controller',
            '臀线 bounce controller',
            '耳朵拖尾 secondary controller',
          ],
          notes: '命中瞬间建议单独暴露 hip squash 与 shoulder lag 两个参数，方便做不同强度版本。',
        ),
        effectLayers: ['心跳光点', '速度线', '星点', '腮红', '呼吸辉光'],
      ),
    ),
    FlirtyAction(
      id: 'lean_closer',
      label: '忽然靠近',
      preview: '小熊忽然朝你压近了一点',
      icon: Icons.zoom_in_map_rounded,
      gradient: [Color(0xFFA06CFF), Color(0xFF85C6FF)],
      hint: '没有接触，张力全靠距离、呼吸和眼神停顿撑起来。',
      stageTitle: '距离压近',
      stageSubtitle: '两只角色压到最近却不碰，像空气被轻轻抽紧，舞台中心只剩呼吸和目光。',
      motionNotes: '前进要慢，悬停要稳，退回要柔；镜头和角色都只推半步。',
      hapticNotes: '距离压到最近点时 medium impact，退回时补 selection click。',
      moodGroup: FlirtyMoodGroup.closer,
      moodTag: 'Heat',
      sceneMoment: '身体先靠近，眼神更先抵达，谁都没碰到谁，但空气已经发烫。',
      loopNotes: '核心不是冲刺，而是慢推近后的停顿呼吸，最后留一点未尽感再退回。',
      assetRecommendation: '角色前倾和镜头景深呼吸适合 Rive，呼吸辉光和粒子尘雾单独做 Lottie。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '停在两人距离最近但还差一口气的位置。',
        previewAnimation: '1.4 秒：慢靠近、停顿、呼吸发亮。',
        fullscreenAnimation: '2.9 秒：加入镜头轻推、目光锁定和慢速退回。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '小熊肩线向前压，小猴上半身微后撤，但眼睛还停在小熊脸上，鼻尖间距留出安全空隙。',
        previewDuration: '1.4s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.5s',
            title: '慢慢压近',
            description: '两人同时轻前倾，小熊主动更多，小猴后撤更细微。',
          ),
          FlirtyBeat(
            timing: '0.5s - 0.95s',
            title: '目光锁住',
            description: '位移停止，只有胸腔呼吸和睫毛轻颤继续运动。',
          ),
          FlirtyBeat(
            timing: '0.95s - 1.4s',
            title: '含笑退半步',
            description: '小熊先退一点，小猴眼神跟着追，热度不立刻散掉。',
          ),
        ],
        fullDuration: '2.9s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.65s',
            title: '肩线压低',
            description: '小熊先把肩膀放松，胸腔前送；小猴意识到靠近后轻轻屏息。',
          ),
          FlirtyBeat(
            timing: '0.65s - 1.45s',
            title: '距离最近点',
            description: '镜头轻推近，背景发光更柔，角色几乎不动，只剩表情和呼吸细动。',
          ),
          FlirtyBeat(
            timing: '1.45s - 2.1s',
            title: '气氛悬停',
            description: '两人维持对视，小猴腮红上浮，小熊嘴角轻提但不坏笑过头。',
          ),
          FlirtyBeat(
            timing: '2.1s - 2.9s',
            title: '慢速回弹',
            description: '小熊先回弹，小猴视线晚 3 帧才移开，保留余温。',
          ),
        ],
        poseNotes: '小熊前倾角度更明显，小猴重心向后但脚不退，制造想逃又没逃开的暧昧。',
        expressionNotes: '小熊是轻微坏笑，小猴是屏住呼吸后的心动和慌张混合。',
        gazeNotes: '整段动作以眼睛为主驱动，最近点必须保持锁定，不要做夸张甩头。',
        forceNotes: '无接触受力，张力由胸腔前送、脖颈前伸和肩线压低来体现。',
        reboundNotes: '回弹不做弹簧感，只做柔和重心回收和呼吸节奏恢复。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'root / pelvis / spine_01 / spine_02 / neck / head',
            'eye_target_l / eye_target_r / jaw / shoulder_l / shoulder_r',
          ],
          controllers: [
            'camera_push controller',
            'breath halo opacity',
            'gaze lock controller',
          ],
          notes: '建议把眼球目标、头部朝向和胸腔呼吸拆开，方便做“眼神先到、身体后到”的节奏。',
        ),
        effectLayers: ['呼吸辉光', '心跳光点', '轻颗粒', '腮红'],
      ),
    ),
    FlirtyAction(
      id: 'pat_head',
      label: '摸摸头',
      preview: '小熊掌心轻轻落在你发顶',
      icon: Icons.pan_tool_alt_rounded,
      gradient: [Color(0xFF8B7BFF), Color(0xFF91D5FF)],
      hint: '重点不是拍下去，是掌心停住那一下的安抚感。',
      stageTitle: '发顶安抚',
      stageSubtitle: '掌心温柔按下，小猴耳朵和眼神一起软掉，空气从暧昧过渡到偏爱的安全感。',
      motionNotes: '掌心下落弧线要圆，头顶压缩和耳朵回弹要软，收手要慢。',
      hapticNotes: '落掌 soft impact，停留结束时 selection click。',
      moodGroup: FlirtyMoodGroup.cute,
      moodTag: 'Warm',
      sceneMoment: '摸头发生的一瞬间，小猴表情明显软下来，像被偏爱稳稳接住。',
      loopNotes: '落手、停留、轻抚收回三段即可，留出发丝和耳朵的软回弹。',
      assetRecommendation: '角色主体和发顶压缩走 Rive，星点与柔光层可用 Lottie。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '掌心刚落到发顶，小猴眼神开始变软的定格。',
        previewAnimation: '1.3 秒：落掌、轻按、耳朵回弹。',
        fullscreenAnimation: '2.6 秒：补足停留、发丝压缩和收手后的余温。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '小熊手掌包住小猴头顶 1/3，手臂形成圆弧；小猴肩膀放松，耳朵微向外展开。',
        previewDuration: '1.3s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.35s',
            title: '掌心落下',
            description: '小熊带着温柔笑意抬手，小猴先短暂停住。',
          ),
          FlirtyBeat(
            timing: '0.35s - 0.8s',
            title: '轻轻按住',
            description: '头顶轻压，耳朵向下软折，表情从微愣变成舒服。',
          ),
          FlirtyBeat(
            timing: '0.8s - 1.3s',
            title: '发丝回弹',
            description: '耳朵和发顶晚一点回弹，眼神仍停在被摸头的满足里。',
          ),
        ],
        fullDuration: '2.6s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.4s',
            title: '抬手靠近',
            description: '小熊先看向小猴头顶，手肘抬起时肩膀保持松弛。',
          ),
          FlirtyBeat(
            timing: '0.4s - 1.05s',
            title: '掌心安抚',
            description: '头顶压缩约 6% 到 8%，小猴眯眼，耳朵轻轻折下。',
          ),
          FlirtyBeat(
            timing: '1.05s - 1.75s',
            title: '停留半拍',
            description: '小熊手不急着收，小猴身体向掌心方向轻贴过去。',
          ),
          FlirtyBeat(
            timing: '1.75s - 2.6s',
            title: '轻抚收回',
            description: '手离开发顶时带一点滑动，小猴耳朵和腮红慢慢恢复。',
          ),
        ],
        poseNotes: '小熊上臂不要抬太高，保持包覆感；小猴脊柱略向掌心方向弯，显得更软。',
        expressionNotes: '小熊是温柔微笑，小猴从日常到害羞再到心动放松。',
        gazeNotes: '摸头前小熊看向发顶，摸头后改看小猴脸；小猴先垂眼再抬一点点看向小熊。',
        forceNotes: '受力点在头顶中心，传导到耳朵和肩线；压缩幅度小但要可见。',
        reboundNotes: '回弹以发丝和耳朵为主，速度比身体慢，像棉花慢慢弹回。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'head_top deform bone',
            'ear_l / ear_r',
            'hand_front / wrist / finger_curl',
          ],
          controllers: [
            'head squash controller',
            'ear softness controller',
            'hand linger blend',
          ],
          notes: '头顶压缩建议做局部 mesh 变形而不是整头缩放，能更可爱也更自然。',
        ),
        effectLayers: ['星点', '呼吸辉光', '腮红', '心跳光点'],
      ),
    ),
    FlirtyAction(
      id: 'hook_finger',
      label: '勾勾手指',
      preview: '小指轻轻勾住了你',
      icon: Icons.gesture_rounded,
      gradient: [Color(0xFFAB73FF), Color(0xFF8FD1FF)],
      hint: '真正动人的不是勾住，而是勾住之前那两次迟疑。',
      stageTitle: '指尖确认',
      stageSubtitle: '两只手先试探，再轻轻勾上，小范围动作却比拥抱更私密。',
      motionNotes: '试探要两次，第一次故意不到位，第二次才成立；成立后整体要安静。',
      hapticNotes: '第一次触碰 selection click，真正勾住时 soft impact。',
      moodGroup: FlirtyMoodGroup.closer,
      moodTag: 'Link',
      sceneMoment: '指尖碰上的瞬间谁都没多动，但心跳像被一起拉住了。',
      loopNotes: '适合两段式：第一次接近失败，第二次勾住后进入轻呼吸停留。',
      assetRecommendation: '指尖、眼球和呼吸节奏都适合 Rive，心跳细闪单独 Lottie。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '两根小指还差一点点就碰到的瞬间。',
        previewAnimation: '1.5 秒：试探、再靠近、轻轻勾住。',
        fullscreenAnimation: '3.0 秒：加入两次犹豫、成立后悬停和微呼吸。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '两人手肘都略收，只有小指向外试探，脸已经先有一点停顿和期待。',
        previewDuration: '1.5s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.45s',
            title: '第一次试探',
            description: '两只手慢慢靠近，但第一下故意没碰上。',
          ),
          FlirtyBeat(
            timing: '0.45s - 0.9s',
            title: '第二次靠近',
            description: '小猴更轻一点，小熊更稳一点，节奏错半拍更有张力。',
          ),
          FlirtyBeat(
            timing: '0.9s - 1.5s',
            title: '勾住停住',
            description: '小指轻勾成立后，身体基本停下，只保留呼吸和眼神。',
          ),
        ],
        fullDuration: '3.0s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.55s',
            title: '手指试探',
            description: '两人都不完全确定，小指先伸，掌心还保持克制。',
          ),
          FlirtyBeat(
            timing: '0.55s - 1.2s',
            title: '第二次接近',
            description: '小熊的手稳稳再往前一点，小猴跟上半拍，终于成功勾住。',
          ),
          FlirtyBeat(
            timing: '1.2s - 2.2s',
            title: '链接成立',
            description: '指尖锁住后几乎没有大动作，只剩胸腔起伏和轻微手指摆动。',
          ),
          FlirtyBeat(
            timing: '2.2s - 3.0s',
            title: '目光停留',
            description: '视线在手和脸之间切一次，最后停回彼此眼睛上。',
          ),
        ],
        poseNotes: '上半身都要收，不做过多肩膀动作；肘部轻贴身体，突出指尖私密感。',
        expressionNotes: '小熊带一点“我知道发生了什么”的微笑，小猴从迟疑到心动。',
        gazeNotes: '前半段看手，后半段看脸；对视只需半拍，不要拖太满。',
        forceNotes: '受力点只在小指勾连，整段靠微小连接和悬停创造强烈情绪。',
        reboundNotes: '没有明显弹跳，只做锁住后极轻微的左右摇摆和呼吸波动。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'forearm_front / wrist / pinky_01 / pinky_02',
            'eye_target / clavicle / chest_breath',
          ],
          controllers: [
            'finger contact blend',
            'linked sway controller',
            'eye contact controller',
          ],
          notes: '如果资源有限，其他手指可合并成手掌 deform，仅单独给小指两段骨骼以保住“勾”的识别度。',
        ),
        effectLayers: ['心跳光点', '轻颗粒', '呼吸辉光', '腮红'],
      ),
    ),
    FlirtyAction(
      id: 'tug_sleeve',
      label: '拽住衣角',
      preview: '小猴害羞地拽住了你的衣角',
      icon: Icons.waving_hand_rounded,
      gradient: [Color(0xFFB582FF), Color(0xFF95D7FF)],
      hint: '不是强行留住，是舍不得你就这样走开。',
      stageTitle: '袖口停留',
      stageSubtitle: '小猴低头轻勾衣角，把小熊往回留了一点点，软绵绵但很有效。',
      motionNotes: '视线先躲开再伸手，拉扯幅度很小，重点在布料张力和犹豫感。',
      hapticNotes: '勾住时 selection click，回拉时 soft impact。',
      moodGroup: FlirtyMoodGroup.cute,
      moodTag: 'Soft',
      sceneMoment: '明明动作很轻，却能把人心一下子勾住，不想再往前走。',
      loopNotes: '伸手、勾住、微拉、想松又没松，节奏要像害羞的人鼓起勇气。',
      assetRecommendation: '角色和手势用 Rive，袖口布料拉伸单独 sprite sheet 或 mesh deform。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '两指勾住衣角、小猴视线垂下的瞬间。',
        previewAnimation: '1.4 秒：低头、伸手、轻拉一下。',
        fullscreenAnimation: '2.8 秒：补足布料张力、肩膀轻颤和迟疑停留。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '小猴站在偏后位置，两指勾住小熊袖口边缘，肩膀微缩，留白多，显得拘谨又可爱。',
        previewDuration: '1.4s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.4s',
            title: '先躲眼神',
            description: '小猴先把视线移开，肩膀缩一点，再慢慢把手伸出去。',
          ),
          FlirtyBeat(
            timing: '0.4s - 0.85s',
            title: '勾住衣角',
            description: '两指夹住袖口边，布料立即形成细小张力线。',
          ),
          FlirtyBeat(
            timing: '0.85s - 1.4s',
            title: '轻轻往回留',
            description: '身体后坐半步，袖口被拉回一点，小猴再偷看小熊反应。',
          ),
        ],
        fullDuration: '2.8s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.55s',
            title: '勇气预备',
            description: '小猴先低头，再像下定决心一样伸手，耳朵稍向后收。',
          ),
          FlirtyBeat(
            timing: '0.55s - 1.1s',
            title: '布料张力建立',
            description: '袖口边缘被勾住，小熊被轻轻拽回，衣料出现柔软拉伸。',
          ),
          FlirtyBeat(
            timing: '1.1s - 2.0s',
            title: '不舍停留',
            description: '小猴没立刻松手，肩膀和指尖都有轻颤，眼神偷偷抬起。',
          ),
          FlirtyBeat(
            timing: '2.0s - 2.8s',
            title: '几乎松手',
            description: '手指略松又重新收住，像在问“你能不能别走”。',
          ),
        ],
        poseNotes: '小猴身体向后收，小熊被拉回半步但保持稳定；动作重点在手和肩膀。',
        expressionNotes: '小猴一定要害羞，小熊的回应是温柔被逗笑而不是夸张惊讶。',
        gazeNotes: '小猴先避开视线，后半段只抬眼看一下；小熊被拉回时第一反应看向手。',
        forceNotes: '受力点在衣角边缘，小猴手指内扣，小熊袖口局部产生轻拉扯变形。',
        reboundNotes: '松手趋势出现后用轻微回拉代替弹跳，质感更软也更亲密。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'sleeve_tip deform',
            'hand_front / finger_pincher',
            'shoulder_shy / neck tuck',
          ],
          controllers: [
            'cloth tension amount',
            'hesitation controller',
            'look-up glance controller',
          ],
          notes: '衣角建议做独立 mesh 或单骨骼拉伸，避免整件衣服一起变形显得太硬。',
        ),
        effectLayers: ['轻颗粒', '腮红', '呼吸辉光', '速度线'],
      ),
    ),
    FlirtyAction(
      id: 'sneak_glance',
      label: '偷看被抓包',
      preview: '小猴偷看你时，被你当场抓包了',
      icon: Icons.visibility_rounded,
      gradient: [Color(0xFF9779FF), Color(0xFF8CD4FF)],
      hint: '真正可爱的是对视后的慌张移开，而不是偷看本身。',
      stageTitle: '余光泄密',
      stageSubtitle: '小猴偏头偷看，小熊突然回头，对视半拍后两人都慌张收神，像空气被点亮一下。',
      motionNotes: '偷看切入要快，被抓包后的脸和眼球回收更快，中间对视停住半拍。',
      hapticNotes: '对视命中时 selection click。',
      moodGroup: FlirtyMoodGroup.stir,
      moodTag: 'Caught',
      sceneMoment: '偷看的心思被抓到之后，脸热和移开视线反而比偷看更暧昧。',
      loopNotes: '用短偷看、短对视、短收回组成不规则节奏，越像真实反应越动人。',
      assetRecommendation: '眼球、眼皮、头部偏转建议 Rive；抓包速度线可用 sprite sheet。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '小猴侧过脸偷看，小熊刚要回头的瞬间。',
        previewAnimation: '1.2 秒：偷看、被抓、慌张移开。',
        fullscreenAnimation: '2.5 秒：加入嘴角没收住、对视停顿和耳尖泛红。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
      storyboard: FlirtyActionStoryboard(
        coverFrame: '小猴只用眼睛和一点点头部偏转看向小熊，小熊还没完全转过来，悬念最强。',
        previewDuration: '1.2s',
        previewBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.3s',
            title: '偷偷偏头',
            description: '小猴头偏、眼先走，嘴角还有一点没收住的笑。',
          ),
          FlirtyBeat(
            timing: '0.3s - 0.65s',
            title: '回头抓包',
            description: '小熊忽然回头，视线正好撞上，小猴瞬间僵住。',
          ),
          FlirtyBeat(
            timing: '0.65s - 1.2s',
            title: '慌张移开',
            description: '小猴快速把脸转回去，耳尖和腮红后知后觉地浮上来。',
          ),
        ],
        fullDuration: '2.5s',
        fullBeats: [
          FlirtyBeat(
            timing: '0.0s - 0.45s',
            title: '余光偷看',
            description: '小猴先用余光试探，再带一点头部角度偏过去，动作很轻。',
          ),
          FlirtyBeat(
            timing: '0.45s - 0.92s',
            title: '瞬间抓到',
            description: '小熊回头速度略快，目光直接锁到小猴脸上，形成短暂停格。',
          ),
          FlirtyBeat(
            timing: '0.92s - 1.55s',
            title: '对视半拍',
            description: '谁都没来得及解释，表情先出卖心思，空气亮一下。',
          ),
          FlirtyBeat(
            timing: '1.55s - 2.5s',
            title: '故作镇定',
            description: '两人都把视线挪开，小猴慌得更明显，小熊则偷笑收回。',
          ),
        ],
        poseNotes: '主体动作集中在头部和眼睛，身体保持相对静止，避免抢掉“偷看”的细腻感。',
        expressionNotes: '小猴从微笑到慌张，小熊从平静到抓包后的轻挑坏笑。',
        gazeNotes: '偷看先走眼睛再走头，被抓包后头部和眼球同时急退，形成慌乱感。',
        forceNotes: '没有接触，动作驱动力来自眼神突发变化和颈部快速回收。',
        reboundNotes: '回收后脸部保留微颤，耳尖和腮红延后出现，制造“心思被看穿”的后劲。',
        rigSuggestion: FlirtyRigSuggestion(
          bones: [
            'neck / head / eye_target_l / eye_target_r / brow_l / brow_r',
            'cheek_blush mask',
          ],
          controllers: [
            'glance snap controller',
            'caught freeze controller',
            'blush reveal opacity',
          ],
          notes: '这个动作对眼球 target 和眼皮 blendshape 很敏感，建议优先保证脸部控制精度。',
        ),
        effectLayers: ['速度线', '腮红', '轻颗粒', '心跳光点'],
      ),
    ),
  ];

  static FlirtyAction byId(String id) {
    return all.firstWhere(
      (item) => item.id == id,
      orElse: () => all.first,
    );
  }
}
