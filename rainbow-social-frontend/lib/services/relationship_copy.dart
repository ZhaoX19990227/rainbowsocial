class RelationshipCopy {
  static String likeSent(String nickname) =>
      '已送出喜欢';

  static String superLikeSent(String nickname) =>
      '已送出超级喜欢';

  static String mutualLike(String nickname) => '你和 $nickname 互相关注了，现在可以展开聊天。';

  static const chatRequiresMutual = '互相关注后才可以聊天。\n先点个喜欢，对方会收到提醒。';
  static const receiveLikeTitle = '收到喜欢';
  static const receiveLikeSubtitle = '有人喜欢了你，回个喜欢就能聊天。';
  static const waitingReplyTitle = '等待回应';
  static const waitingReplySubtitle = '你送出的喜欢已通知对方，\n互相关注后即可聊天。';
  static const mutualLikeTitle = '互相喜欢';
  static const mutualLikeSubtitle = '已经可以聊天了，去打个招呼吧。';
}
