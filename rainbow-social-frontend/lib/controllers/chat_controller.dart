import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_user.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import '../providers/app_providers.dart';
import '../services/api_config.dart';
import '../state/chat_list_state.dart';
import '../state/chat_room_state.dart';
import '../usecases/chat_usecases.dart';
import 'auth_controller.dart';

final chatThreadsControllerProvider =
    StateNotifierProvider<ChatThreadsController, ChatListState>((ref) {
  return ChatThreadsController(ref);
});

final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatRoomState, AppUser>((ref, peer) {
  return ChatController(ref, peer);
});

class ChatThreadsController extends StateNotifier<ChatListState> {
  ChatThreadsController(this._ref)
      : super(const ChatListState(isLoading: true)) {
    loadThreads();
  }

  final Ref _ref;

  Future<void> loadThreads() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const ChatListState(threads: []);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final threads = await _ref
          .read(getConversationSummariesUseCaseProvider)(session.token);
      state = ChatListState(threads: threads);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '会话列表加载失败：$error',
      );
    }
  }

  Future<void> togglePinned(ChatThread thread) async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    final original = state.threads;
    final updatedThread = thread.copyWith(isPinned: !thread.isPinned);
    final updatedThreads = original
        .map((item) => item.peer.id == thread.peer.id ? updatedThread : item)
        .toList();
    state =
        state.copyWith(threads: _sortThreads(updatedThreads), clearError: true);

    try {
      await _ref.read(setConversationPinnedUseCaseProvider).call(
            token: session.token,
            peerId: thread.peer.id,
            isPinned: !thread.isPinned,
          );
      await loadThreads();
    } catch (error) {
      state = state.copyWith(
        threads: original,
        errorMessage: '会话置顶更新失败：$error',
      );
    }
  }

  Future<void> refreshAfterRead(int peerId) async {
    final updatedThreads = state.threads
        .map((item) =>
            item.peer.id == peerId ? item.copyWith(unreadCount: 0) : item)
        .toList();
    state = state.copyWith(threads: updatedThreads, clearError: true);
    await loadThreads();
  }

  void upsertThreadPreview(
    AppUser peer,
    ChatMessageModel message, {
    bool resetUnread = false,
    bool incrementUnread = false,
  }) {
    final index = state.threads.indexWhere((item) => item.peer.id == peer.id);
    if (index < 0) {
      final inserted = ChatThread(
        peer: peer,
        lastMessage: message.copyWith(status: ChatMessageStatus.sent),
        unreadCount: incrementUnread ? 1 : 0,
        isPinned: false,
      );
      state = state.copyWith(
        threads: _sortThreads([...state.threads, inserted]),
        clearError: true,
      );
      return;
    }

    final current = state.threads[index];
    final updated = current.copyWith(
      lastMessage: message.copyWith(status: ChatMessageStatus.sent),
      unreadCount: resetUnread
          ? 0
          : incrementUnread
              ? current.unreadCount + 1
              : current.unreadCount,
    );
    final items = [...state.threads];
    items[index] = updated;
    state = state.copyWith(threads: _sortThreads(items), clearError: true);
  }

  List<ChatThread> _sortThreads(List<ChatThread> items) {
    final sorted = [...items];
    sorted.sort((left, right) {
      if (left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      return right.lastMessage.timestamp.compareTo(left.lastMessage.timestamp);
    });
    return sorted;
  }
}

class ChatController extends StateNotifier<ChatRoomState> {
  ChatController(this._ref, this.peer)
      : super(const ChatRoomState(isLoading: true)) {
    _initialize();
  }

  final Ref _ref;
  final AppUser peer;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  void _initialize() {
    _loadHistory();
    _connectSocket();
  }

  Future<void> _loadHistory() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = const ChatRoomState(messages: []);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items =
          await _ref.read(getConversationMessagesUseCaseProvider).call(
                token: session.token,
                peerId: peer.id,
              );
      state =
          state.copyWith(messages: items, isLoading: false, clearError: true);
      await _markConversationRead();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '消息加载失败：$error',
      );
    }
  }

  Future<void> _markConversationRead() async {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      await _ref.read(markConversationReadUseCaseProvider).call(
            token: session.token,
            peerId: peer.id,
          );
      await _ref
          .read(chatThreadsControllerProvider.notifier)
          .refreshAfterRead(peer.id);
    } catch (_) {
      // Ignore read-state sync failures in the room UI.
    }
  }

  void _connectSocket() {
    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      _channel = _ref.read(chatServiceProvider).connect(
            wsBaseUrl: ApiConfig.wsBaseUrl,
            userId: session.user.id,
            token: session.token,
          );
      _subscription = _channel!.stream.listen(
        _handleSocketEvent,
        onDone: _handleSocketDone,
        onError: (_) => _handleSocketDone(),
      );
    } catch (_) {
      // Keep history mode when websocket is unavailable.
    }
  }

  void _handleSocketEvent(dynamic event) {
    final payload = jsonDecode(event as String) as Map<String, dynamic>;
    final eventName = '${payload['event'] ?? ''}';
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return;

    switch (eventName) {
      case 'message':
        _handleIncomingMessage(ChatMessageModel.fromJson(data));
        break;
      case 'message_error':
        _handleMessageError(
          clientMessageId: '${data['client_message_id'] ?? ''}',
          error: '${data['error'] ?? '发送失败'}',
        );
        break;
    }
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    if (message.fromUser != peer.id && message.toUser != peer.id) {
      return;
    }

    final currentUserId =
        _ref.read(authControllerProvider).valueOrNull?.user.id ?? -1;
    final isOutgoingAck = message.isMine(currentUserId) &&
        message.clientMessageId.isNotEmpty &&
        state.messages.any(
          (item) =>
              item.clientMessageId == message.clientMessageId && item.isPending,
        );

    if (isOutgoingAck) {
      state = state.copyWith(
        messages: state.messages
            .map((item) => item.clientMessageId == message.clientMessageId
                ? message.copyWith(status: ChatMessageStatus.sent)
                : item)
            .toList(),
        sendingCount: _pendingCountAfterResolve(message.clientMessageId),
        clearError: true,
      );
    } else {
      final exists = state.messages.any(
        (item) =>
            (message.id != 0 && item.id == message.id) ||
            (message.clientMessageId.isNotEmpty &&
                item.clientMessageId == message.clientMessageId),
      );
      if (!exists) {
        state = state.copyWith(
          messages: [...state.messages, message],
          clearError: true,
        );
      }
    }

    if (message.fromUser == peer.id) {
      _ref.read(chatThreadsControllerProvider.notifier).upsertThreadPreview(
            peer,
            message,
            resetUnread: true,
          );
      _markConversationRead();
    } else {
      _ref.read(chatThreadsControllerProvider.notifier).upsertThreadPreview(
            peer,
            message,
            resetUnread: true,
          );
    }
  }

  void _handleMessageError({
    required String clientMessageId,
    required String error,
  }) {
    if (clientMessageId.isEmpty) {
      state = state.copyWith(errorMessage: error);
      return;
    }

    state = state.copyWith(
      messages: state.messages
          .map((item) => item.clientMessageId == clientMessageId
              ? item.copyWith(
                  status: ChatMessageStatus.failed,
                  errorMessage: error,
                )
              : item)
          .toList(),
      sendingCount: _pendingCountAfterResolve(clientMessageId),
      errorMessage: error,
    );
  }

  void _handleSocketDone() {
    final failedMessages = state.messages
        .map((item) => item.isPending
            ? item.copyWith(
                status: ChatMessageStatus.failed,
                errorMessage: '连接已中断，请点击重试',
              )
            : item)
        .toList();
    state = state.copyWith(
      messages: failedMessages,
      sendingCount: 0,
      errorMessage: '连接已中断，请稍后重试',
    );
  }

  Future<void> sendMessage(String input) async {
    final text = input.trim();
    if (text.isEmpty) return;

    final session = _ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    final optimisticMessage = ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch,
      clientMessageId: _buildClientMessageId(),
      fromUser: session.user.id,
      toUser: peer.id,
      content: text,
      type: 'text',
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMessage],
      sendingCount: state.sendingCount + 1,
      clearError: true,
    );
    _ref.read(chatThreadsControllerProvider.notifier).upsertThreadPreview(
          peer,
          optimisticMessage,
          resetUnread: true,
        );

    await _dispatchMessage(optimisticMessage);
  }

  Future<void> retryMessage(ChatMessageModel message) async {
    state = state.copyWith(
      messages: state.messages
          .map((item) => item.clientMessageId == message.clientMessageId
              ? item.copyWith(
                  status: ChatMessageStatus.sending,
                  clearError: true,
                )
              : item)
          .toList(),
      sendingCount: state.sendingCount + 1,
      clearError: true,
    );

    await _dispatchMessage(
      message.copyWith(
        status: ChatMessageStatus.sending,
        clearError: true,
      ),
    );
  }

  Future<void> _dispatchMessage(ChatMessageModel message) async {
    try {
      if (_channel == null) {
        throw Exception('当前聊天连接不可用');
      }

      _channel!.sink.add(
        _ref.read(chatRepositoryProvider).encodeOutbound(
              clientMessageId: message.clientMessageId,
              toUser: peer.id,
              content: message.content,
            ),
      );
    } catch (error) {
      _handleMessageError(
        clientMessageId: message.clientMessageId,
        error: '发送失败，请检查网络后重试',
      );
      state = state.copyWith(errorMessage: '$error');
    }
  }

  int _pendingCountAfterResolve(String clientMessageId) {
    return state.messages
        .where(
          (item) => item.isPending && item.clientMessageId != clientMessageId,
        )
        .length;
  }

  String _buildClientMessageId() {
    final userId = _ref.read(authControllerProvider).valueOrNull?.user.id ?? 0;
    return '${userId}_${peer.id}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
