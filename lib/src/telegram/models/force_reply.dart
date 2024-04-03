part of 'models.dart';

/// Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot's message and tapped 'Reply'). This can be extremely useful if you want to create user-friendly step-by-step interfaces without having to sacrifice privacy mode.
class ForceReply extends ReplyMarkup {
  /// Shows reply interface to the user, as if they manually selected the bot's message and tapped 'Reply'
  final bool forceReply;

  /// Optional. The placeholder to be shown in the input field when the reply is active; 1-64 characters
  final String? inputFieldPlaceholder;

  /// Optional. Use this parameter if you want to force reply from specific users only. Targets: 1) users that are @mentioned in the text of the Message object; 2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.
  final bool? selective;

  /// Constructs a [ForceReply] object.
  const ForceReply({
    this.forceReply = true,
    this.selective,
    this.inputFieldPlaceholder,
  });

  /// Creates a [ForceReply] object from json.
  factory ForceReply.fromJson(Map<String, dynamic> json) {
    return ForceReply(
      forceReply: json['force_reply'],
      selective: json['selective'],
      inputFieldPlaceholder: json['input_field_placeholder'],
    );
  }

  /// Converts a [ForceReply] object to json.
  @override
  Map<String, dynamic> toJson() {
    return {
      'force_reply': forceReply,
      'selective': selective,
      'input_field_placeholder': inputFieldPlaceholder,
    }..removeWhere(_nullFilter);
  }
}
