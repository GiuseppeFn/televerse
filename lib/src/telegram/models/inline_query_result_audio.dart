part of 'models.dart';

/// Represents a link to an MP3 audio file. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio.
///
/// Note: This will only work in Telegram versions released after 9 April, 2016. Older clients will ignore them.
class InlineQueryResultAudio implements InlineQueryResult {
  /// Unique identifier for this result, 1-64 Bytes
  @override
  final String id;

  /// Type of the result, always [InlineQueryResultType.audio]
  @override
  InlineQueryResultType get type => InlineQueryResultType.audio;

  /// A valid URL for the audio file
  final String audioUrl;

  /// Title
  final String title;

  /// Optional. Caption, 0-1024 characters after entities parsing
  final String? caption;

  /// Optional. Mode for parsing entities in the audio caption. See formatting options for more details.
  final ParseMode? parseMode;

  /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
  final List<MessageEntity>? captionEntities;

  /// Optional. Performer
  final String? performer;

  /// Optional. Audio duration in seconds
  final int? audioDuration;

  /// Optional. Inline keyboard attached to the message
  final InlineKeyboardMarkup? replyMarkup;

  /// Optional. Content of the message to be sent instead of the audio
  @override
  final InputMessageContent? inputMessageContent;

  /// Constructs an [InlineQueryResultAudio] object
  const InlineQueryResultAudio({
    required this.audioUrl,
    required this.title,
    required this.id,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.performer,
    this.audioDuration,
    this.replyMarkup,
    this.inputMessageContent,
  });

  /// Converts an [InlineQueryResultAudio] object to a JSON map
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'audio_url': audioUrl,
      'title': title,
      'caption': caption,
      'parse_mode': parseMode?.value,
      'caption_entities': captionEntities?.map((e) => e.toJson()).toList(),
      'performer': performer,
      'audio_duration': audioDuration,
      'reply_markup': replyMarkup?.toJson(),
      'input_message_content': inputMessageContent?.toJson(),
      'id': id,
    }..removeWhere(_nullFilter);
  }

  /// Constructs an [InlineQueryResultAudio] object from a JSON map
  factory InlineQueryResultAudio.fromJson(Map<String, dynamic> json) {
    return InlineQueryResultAudio(
      audioUrl: json['audio_url'] as String,
      title: json['title'] as String,
      id: json['id'] as String,
      caption: json['caption'] as String?,
      parseMode: json['parse_mode'] == null
          ? null
          : ParseMode.fromJson(json['parse_mode'] as String),
      captionEntities: (json['caption_entities'] as List<dynamic>?)
          ?.map((e) => MessageEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      performer: json['performer'] as String?,
      audioDuration: json['audio_duration'] as int?,
      replyMarkup: json['reply_markup'] == null
          ? null
          : InlineKeyboardMarkup.fromJson(
              json['reply_markup'] as Map<String, dynamic>,
            ),
      inputMessageContent: json['input_message_content'] == null
          ? null
          : InputMessageContent.fromJson(
              json['input_message_content'] as Map<String, dynamic>,
            ),
    );
  }
}
