import '../models/app_user.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';

class MockSocialData {
  static final List<AppUser> users = [
    const AppUser(
      id: 1,
      email: 'julian@example.com',
      nickname: 'Julian',
      avatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
      photos: [],
      age: 28,
      heightCm: 181,
      weightKg: 76,
      birthday: '1996-11-03',
      zodiacSign: 'Scorpio',
      mbtiType: 'ENFJ',
      bio:
          'Architect by day, salsa dancer by night. Looking for someone who appreciates a good espresso and better conversation.',
      tags: ['旅行', '健身', '咖啡'],
      positionRole: 'Top',
      lat: 31.2304,
      lng: 121.4737,
      onlineStatus: true,
      locationLabel: '上海 静安',
      distanceKm: 2.0,
    ),
    const AppUser(
      id: 2,
      email: 'alex@example.com',
      nickname: 'Alex',
      avatar:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=900&q=80',
      photos: [],
      age: 24,
      heightCm: 176,
      weightKg: 68,
      birthday: '2000-02-26',
      zodiacSign: 'Pisces',
      mbtiType: 'INFP',
      bio: 'Soft-spoken design nerd, gallery lover, and late-night walker.',
      tags: ['设计', '展览', 'Brunch'],
      positionRole: 'Vers',
      lat: 31.2203,
      lng: 121.4281,
      onlineStatus: true,
      locationLabel: '上海 徐汇',
      distanceKm: 1.2,
    ),
    const AppUser(
      id: 3,
      email: 'leo@example.com',
      nickname: 'Leo',
      avatar:
          'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=900&q=80',
      photos: [],
      age: 26,
      heightCm: 179,
      weightKg: 72,
      birthday: '1998-06-14',
      zodiacSign: 'Gemini',
      mbtiType: 'ENTP',
      bio: 'Jazz clubs, digital art, and a weakness for dramatic skylines.',
      tags: ['爵士', '建筑', '夜生活'],
      positionRole: 'Vers Top',
      lat: 31.2342,
      lng: 121.4822,
      onlineStatus: true,
      locationLabel: '上海 黄浦',
      distanceKm: 0.8,
    ),
    const AppUser(
      id: 4,
      email: 'marcus@example.com',
      nickname: 'Marcus',
      avatar:
          'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=900&q=80',
      photos: [],
      age: 30,
      heightCm: 184,
      weightKg: 80,
      birthday: '1994-01-18',
      zodiacSign: 'Capricorn',
      mbtiType: 'ISTJ',
      bio:
          'Runner, cookbook collector, and always planning the next city escape.',
      tags: ['跑步', '美食', '旅行'],
      positionRole: 'Bottom',
      lat: 31.205,
      lng: 121.455,
      onlineStatus: false,
      locationLabel: '上海 长宁',
      distanceKm: 2.5,
    ),
  ];

  static final List<ChatThread> threads = [
    ChatThread(
      peer: users[2],
      unreadCount: 2,
      isPinned: true,
      lastMessage: ChatMessageModel(
        id: 1,
        clientMessageId: 'mock-thread-1',
        fromUser: 3,
        toUser: 99,
        content: '今晚那家霓虹艺术馆，我还在想着。',
        type: 'text',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
    ),
    ChatThread(
      peer: users[1],
      unreadCount: 0,
      isPinned: false,
      lastMessage: ChatMessageModel(
        id: 2,
        clientMessageId: 'mock-thread-2',
        fromUser: 99,
        toUser: 2,
        content: '如果你愿意，我们晚饭后可以见面。',
        type: 'text',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ),
  ];

  static List<ChatMessageModel> initialMessages(int currentUserId, int peerId) {
    return [
      ChatMessageModel(
        id: 11,
        clientMessageId: 'mock-message-11',
        fromUser: peerId,
        toUser: currentUserId,
        content: '我刚刚还在想那家霓虹灯很漂亮的地方。',
        type: 'text',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ChatMessageModel(
        id: 12,
        clientMessageId: 'mock-message-12',
        fromUser: currentUserId,
        toUser: peerId,
        content: '是那家黑曜画廊吗？我很想去。',
        type: 'text',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessageModel(
        id: 13,
        clientMessageId: 'mock-message-13',
        fromUser: peerId,
        toUser: currentUserId,
        content: '现在现场看起来特别梦幻。',
        type: 'text',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ];
  }
}
