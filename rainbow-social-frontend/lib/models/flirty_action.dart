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
        return 'Tease A Little';
      case FlirtyMoodGroup.closer:
        return 'Get Closer';
      case FlirtyMoodGroup.cute:
        return 'Act Cute';
      case FlirtyMoodGroup.stir:
        return 'Stir The Mood';
    }
  }

  String get subtitle {
    switch (this) {
      case FlirtyMoodGroup.tease:
        return '轻坏一下，让气氛先升温。';
      case FlirtyMoodGroup.closer:
        return '把距离悄悄缩短一点。';
      case FlirtyMoodGroup.cute:
        return '软一点，黏一点，更像在撒娇。';
      case FlirtyMoodGroup.stir:
        return '不明说，但足够让人心跳加速。';
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

  static const all = <FlirtyAction>[
    FlirtyAction(
      id: 'poke_butt',
      label: '坏坏戳一下',
      preview: '指尖坏坏点了点你一下',
      icon: Icons.back_hand_rounded,
      gradient: [Color(0xFFDE8A69), Color(0xFF4C1E28)],
      hint: '坏心思先落下去，笑意再慢半拍追上来。',
      stageTitle: '坏坏偷袭',
      stageSubtitle: '指尖点一下就撤，留给对方一个夸张到可爱的反应弹跳。',
      motionNotes: '前 15% 蓄力歪头，20% 快戳命中，随后 2 次弹性回弹。',
      hapticNotes: '命中一瞬间 medium impact，第二次回弹加一次 light tick。',
      moodGroup: FlirtyMoodGroup.tease,
      moodTag: 'Tease',
      sceneMoment: '他忍着笑往前一探，指尖点到的瞬间，对方整个人像被电到一样弹开半步。',
      loopNotes: '采用三段循环: 蓄力 -> 轻戳 -> 臀部和肩线同步回弹，再回到坏笑待机。',
      assetRecommendation: '主角与受击 bounce 用 Rive，命中星点和速度线用 sprite sheet。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '定格在坏笑侧身、指尖即将命中的半拍前。',
        previewAnimation: '1.2 秒三段式预览: 蓄力、轻戳、双重回弹。',
        fullscreenAnimation: '2.5 秒完整版，包含夸张臀部 bounce、肩线晃动和回头羞恼表情。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
    ),
    FlirtyAction(
      id: 'tug_sleeve',
      label: '拽住衣角',
      preview: '悄悄勾住了你的袖口',
      icon: Icons.waving_hand_rounded,
      gradient: [Color(0xFFC18C63), Color(0xFF49303B)],
      hint: '不是拦住你，是舍不得让你走快一点。',
      stageTitle: '袖口停留',
      stageSubtitle: '手指只是轻轻勾住，空气却会因此变得更黏一点。',
      motionNotes: '先探手停顿，再小幅回拉，末尾补一个带呼吸感的迟疑收手。',
      hapticNotes: '勾住袖口时 selection click，回拉时补一个极轻 soft impact。',
      moodGroup: FlirtyMoodGroup.cute,
      moodTag: 'Soft',
      sceneMoment: '害羞的那位先垂眼，又像鼓起勇气一样勾住对方袖口，轻轻把人往自己这边留一下。',
      loopNotes: '待机时保留袖口晃动和肩膀轻颤，形成“想松手又没舍得”的循环。',
      assetRecommendation: '角色主体用 Rive，袖口拉扯布料变形可用序列帧或 sprite sheet。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '停在袖口被两指轻轻勾住、视线垂下的一瞬间。',
        previewAnimation: '1.4 秒轻探手到小回拉，保留袖口张力和肩膀轻颤。',
        fullscreenAnimation: '2.8 秒完整版，加入布料拉伸、呼吸停顿、松手前迟疑。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
    ),
    FlirtyAction(
      id: 'pat_head',
      label: '摸摸你的头',
      preview: '掌心轻轻落在你的发顶',
      icon: Icons.pan_tool_alt_rounded,
      gradient: [Color(0xFF7E8EE4), Color(0xFF393064)],
      hint: '掌心落下来的那一下，像安抚，也像偏爱。',
      stageTitle: '发顶安抚',
      stageSubtitle: '手没有很快收走，像故意把温柔停留给你看。',
      motionNotes: '手掌柔和落下，头发微压再回弹，停留半拍后带笑收回。',
      hapticNotes: '手掌落下时 soft impact，停留结束时 selection tick。',
      moodGroup: FlirtyMoodGroup.cute,
      moodTag: 'Warm',
      sceneMoment: '主动的那位把掌心轻轻压在发顶，对方先愣一下，再因为被摸头而软下来。',
      loopNotes: '适合做轻循环: 落手拍一下 -> 停住眯眼 -> 发丝与耳朵小幅回弹。',
      assetRecommendation: '角色姿态和发丝形变适合 Rive，发顶小星点可用 Lottie。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '掌心刚落在发顶，另一方眼神开始软下来的定格。',
        previewAnimation: '1.3 秒落手、轻拍、停留。',
        fullscreenAnimation: '2.4 秒完整版，增加发丝压缩回弹和眯眼回应。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
    ),
    FlirtyAction(
      id: 'hook_finger',
      label: '勾住手指',
      preview: '小指轻轻勾住了你',
      icon: Icons.gesture_rounded,
      gradient: [Color(0xFFE2B17B), Color(0xFF5A2E35)],
      hint: '比牵手更轻，却更像一句只说给你听的话。',
      stageTitle: '指尖确认',
      stageSubtitle: '不是一下握住，而是先试探地碰，再慢慢把小指勾住。',
      motionNotes: '两次接近后才真正勾住，勾上后做极轻的心跳式晃动停留。',
      hapticNotes: '第一次触碰用 selection click，真正勾住时 soft impact。',
      moodGroup: FlirtyMoodGroup.closer,
      moodTag: 'Intimate',
      sceneMoment: '两只手先在空气里迟疑了一下，第二次靠近才真正把小指勾住，眼神也因此停住。',
      loopNotes: '建议做双段式节奏: 试探接近 -> 勾住停留；停留时只保留指尖晃动和呼吸。',
      assetRecommendation: '这是最适合 Rive 的主打场景，指尖连接和视线停顿都需要可控骨骼动画。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '两只小指还差一点点接触、眼神已经先停住的时刻。',
        previewAnimation: '1.5 秒双段式: 试探接近、停顿、真正勾住。',
        fullscreenAnimation: '3 秒完整版，包含两次犹豫、指尖锁住、呼吸感悬停。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
    ),
    FlirtyAction(
      id: 'lean_closer',
      label: '忽然靠近',
      preview: '突然朝你靠近了一点',
      icon: Icons.zoom_in_map_rounded,
      gradient: [Color(0xFF8C6178), Color(0xFF231A2E)],
      hint: '明明还没碰到，气压已经低下来了一点。',
      stageTitle: '靠近半步',
      stageSubtitle: '身体只往前送半步，真正先抵达的是眼神和呼吸。',
      motionNotes: '以镜头推近和角色前倾同步，近距离停顿后再缓慢退回呼吸位。',
      hapticNotes: '距离压到最近点时 medium impact。',
      moodGroup: FlirtyMoodGroup.closer,
      moodTag: 'Close',
      sceneMoment: '主动的人先压低肩线往前靠，另一个下意识屏住一下呼吸，眼神完全来不及躲开。',
      loopNotes: '避免频繁冲刺，建议做慢靠近和悬停循环，强调停顿比位移更重要。',
      assetRecommendation: '角色前倾和镜头层次适合 Rive，背景景深呼吸光建议用 shader 或 Lottie。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '停在距离最近但还没碰到的半步，目光已经锁住。',
        previewAnimation: '1.4 秒慢靠近加短暂停顿，强调眼神先到。',
        fullscreenAnimation: '2.8 秒完整版，镜头轻推近、呼吸停顿、再缓慢退回。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'Lottie',
      ),
    ),
    FlirtyAction(
      id: 'sneak_glance',
      label: '偏头偷看',
      preview: '侧过脸偷偷看了你一眼',
      icon: Icons.visibility_rounded,
      gradient: [Color(0xFF7094C8), Color(0xFF23334C)],
      hint: '明明想装没事，眼神还是把心思先交代了。',
      stageTitle: '余光泄密',
      stageSubtitle: '先是偏头偷看，发现被抓到后才慢半拍地假装无事发生。',
      motionNotes: '偷看切入要快，被发现后的收回更快，中间留一个很短的对视停点。',
      hapticNotes: '对视命中时 light tick。',
      moodGroup: FlirtyMoodGroup.tease,
      moodTag: 'Glance',
      sceneMoment: '害羞的那位偷看时嘴角还没来得及收好，刚好撞上对方回头，于是慌张把脸别开。',
      loopNotes: '适合做不规则循环，加入长短不同的偷看间隔会更像真人反应。',
      assetRecommendation: '脸部表情与视线建议 Rive，瞬间收回的小速度线可用 sprite sheet。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '偷看被抓包前的余光定格。',
        previewAnimation: '1.1 秒偷看、对视、慌张收回。',
        fullscreenAnimation: '2.2 秒完整版，加入表情补救和耳尖泛红。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'sprite sheet',
      ),
    ),
    FlirtyAction(
      id: 'brush_shoulder',
      label: '轻蹭肩膀',
      preview: '肩侧若有若无地擦过你',
      icon: Icons.airline_seat_recline_extra_rounded,
      gradient: [Color(0xFF5F96B4), Color(0xFF1E3146)],
      hint: '像路过时没躲开，又像故意留了一点接触。',
      stageTitle: '肩线擦过',
      stageSubtitle: '不是撞上去，是在错身时故意放慢半拍，让肩膀轻轻带过去。',
      motionNotes: '贴近要顺，接触要轻，擦过后一定要给一个回头确认反应。',
      hapticNotes: '接触峰值 very light impact。',
      moodGroup: FlirtyMoodGroup.stir,
      moodTag: 'Tension',
      sceneMoment: '两个人错身的瞬间肩膀轻轻擦过，回头那一下比接触本身更暧昧。',
      loopNotes: '适合横向位移循环，核心不是撞感，而是擦肩后的迟到半拍回望。',
      assetRecommendation: '角色位移适合 Rive，擦肩光痕和拖尾用 sprite sheet 或 APNG。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '擦肩刚结束、两人回头错开半拍的定格。',
        previewAnimation: '1.4 秒横向错身和迟到回望。',
        fullscreenAnimation: '2.6 秒完整版，加入肩线擦过的拖尾和微弱停顿。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'APNG',
      ),
    ),
    FlirtyAction(
      id: 'naughty_smile',
      label: '给你坏笑',
      preview: '嘴角一挑，冲你坏笑了一下',
      icon: Icons.mood_rounded,
      gradient: [Color(0xFFC97358), Color(0xFF4B2037)],
      hint: '什么都没说，但节奏已经被他拿走了。',
      stageTitle: '笑意挑衅',
      stageSubtitle: '不是夸张的大笑，只是一点抬眼和一侧嘴角，就足够让人乱掉节拍。',
      motionNotes: '先抬眼，再单边扬唇，最后补一记慢眨眼，停在最有杀伤力的瞬间。',
      hapticNotes: '笑意定格时 selection click。',
      moodGroup: FlirtyMoodGroup.stir,
      moodTag: 'Smirk',
      sceneMoment: '主动的那位先看过来，再一点点把笑意抬上嘴角，对方的耳朵明显先红。',
      loopNotes: '用长待机配短表情爆点，让“坏笑一下”更像被抓拍到的瞬间。',
      assetRecommendation: '这类面部主导场景适合 Rive；如果资源有限，可退化成 APNG 循环。',
      assetPlan: FlirtyAssetPlan(
        coverFrame: '坏笑刚扬起来、对面已经耳热的瞬间。',
        previewAnimation: '1.1 秒抬眼、扬唇、慢眨眼。',
        fullscreenAnimation: '2.2 秒完整版，强调眼神停顿和对面反应。',
        coverFormat: 'static png/webp',
        previewFormat: 'Rive',
        fullscreenFormat: 'Rive',
        effectsFormat: 'APNG',
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
