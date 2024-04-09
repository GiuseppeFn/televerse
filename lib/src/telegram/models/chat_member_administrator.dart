part of 'models.dart';

/// Represents a chat member that owns the chat and has all administrator privileges.
class ChatMemberAdministrator implements ChatMember, WithUser {
  /// The member's status in the chat, always [ChatMemberStatus.administrator]
  @override
  final ChatMemberStatus status = ChatMemberStatus.administrator;

  /// Information about the user
  @override
  final User user;

  /// True, if the bot is allowed to edit administrator privileges of that user
  final bool canBeEdited;

  /// True, if the user's presence in the chat is hidden
  final bool isAnonymous;

  /// True, if the administrator can access the chat event log, chat statistics, message statistics in channels, see channel members, see anonymous administrators in supergroups and ignore slow mode. Implied by any other administrator privilege
  final bool canManageChat;

  /// True, if the administrator can delete messages of other users
  final bool canDeleteMessages;

  /// True, if the administrator can manage video chats
  final bool canManageVideoChats;

  /// True, if the administrator can restrict, ban or unban chat members
  final bool canRestrictMembers;

  /// True, if the administrator can add new administrators with a subset of their own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by the user)
  final bool canPromoteMembers;

  /// True, if the user is allowed to change the chat title, photo and other settings
  final bool canChangeInfo;

  /// True, if the user is allowed to invite new users to the chat
  final bool canInviteUsers;

  /// Optional. True, if the administrator can post in the channel; channels only
  final bool? canPostMessages;

  /// Optional. True, if the administrator can edit messages of other users and can pin messages; channels only
  final bool? canEditMessages;

  /// Optional. True, if the user is allowed to pin messages; groups and supergroups only
  final bool? canPinMessages;

  /// Optional. True, if the user is allowed to create, rename, close, and reopen forum topics; supergroups only
  final bool? canManageTopics;

  /// Custom title for this user
  final String? customTitle;

  /// Optional. True, if the administrator can post stories in the channel; channels only
  final bool? canPostStories;

  /// Optional. True, if the administrator can edit stories posted by other users; channels only
  final bool? canEditStories;

  /// Optional. True, if the administrator can delete stories posted by other users
  final bool? canDeleteStories;

  /// Creates a new [ChatMemberAdministrator] object.
  const ChatMemberAdministrator({
    required this.user,
    required this.canBeEdited,
    required this.isAnonymous,
    required this.canManageChat,
    required this.canDeleteMessages,
    required this.canManageVideoChats,
    required this.canRestrictMembers,
    required this.canPromoteMembers,
    required this.canChangeInfo,
    required this.canInviteUsers,
    this.canPostMessages,
    this.canEditMessages,
    this.canPinMessages,
    this.canManageTopics,
    this.customTitle,
    this.canPostStories,
    this.canEditStories,
    this.canDeleteStories,
  });

  /// Converts this object to json.
  @override
  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'user': user.toJson(),
      'can_be_edited': canBeEdited,
      'is_anonymous': isAnonymous,
      'can_manage_chat': canManageChat,
      'can_delete_messages': canDeleteMessages,
      'can_manage_video_chats': canManageVideoChats,
      'can_restrict_members': canRestrictMembers,
      'can_promote_members': canPromoteMembers,
      'can_change_info': canChangeInfo,
      'can_invite_users': canInviteUsers,
      'can_post_messages': canPostMessages,
      'can_edit_messages': canEditMessages,
      'can_pin_messages': canPinMessages,
      'can_manage_topics': canManageTopics,
      'custom_title': customTitle,
      'can_post_stories': canPostStories,
      'can_edit_stories': canEditStories,
      'can_delete_stories': canDeleteStories,
    }..removeWhere(_nullFilter);
  }

  /// Creates a new [ChatMemberAdministrator] object from json.
  factory ChatMemberAdministrator.fromJson(Map<String, dynamic> json) {
    return ChatMemberAdministrator(
      user: User.fromJson(json['user']),
      canBeEdited: json['can_be_edited'],
      isAnonymous: json['is_anonymous'],
      canManageChat: json['can_manage_chat'],
      canDeleteMessages: json['can_delete_messages'],
      canManageVideoChats: json['can_manage_video_chats'],
      canRestrictMembers: json['can_restrict_members'],
      canPromoteMembers: json['can_promote_members'],
      canChangeInfo: json['can_change_info'],
      canInviteUsers: json['can_invite_users'],
      canPostMessages: json['can_post_messages'],
      canEditMessages: json['can_edit_messages'],
      canPinMessages: json['can_pin_messages'],
      canManageTopics: json['can_manage_topics'],
      customTitle: json['custom_title'],
      canPostStories: json['can_post_stories'],
      canEditStories: json['can_edit_stories'],
      canDeleteStories: json['can_delete_stories'],
    );
  }

  /// Information about the user
  @override
  User get from => user;
}
