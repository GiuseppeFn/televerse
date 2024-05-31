part of 'models.dart';

/// Represents a photo to be sent.
class InputMediaPhoto extends InputMedia {
  /// Type of the result, must be photo
  @override
  final InputMediaType type = InputMediaType.photo;

  /// Optional. Caption of the photo to be sent, 0-1024 characters after entities parsing
  final String? caption;

  /// Optional. Mode for parsing entities in the photo caption. See formatting options for more details.
  final ParseMode? parseMode;

  /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
  final List<MessageEntity>? captionEntities;

  /// Optional. Pass True if the photo needs to be covered with a spoiler animation
  final bool? hasSpoiler;

  /// Optional. True, if the caption must be shown above the message media
  final bool? showCaptionAboveMedia;

  /// Constructs an [InputMediaPhoto] object
  const InputMediaPhoto({
    required super.media,
    this.caption,
    this.parseMode,
    this.captionEntities,
    this.hasSpoiler,
    this.showCaptionAboveMedia,
  });

  /// Converts an [InputMediaPhoto] object to a JSON object
  @override
  Map<String, dynamic> getValue([String? field, String? thumb]) {
    return {
      'type': type.value,
      'media': media.getValue(field),
      'caption': caption,
      'parse_mode': parseMode?.value,
      'caption_entities': captionEntities,
      'has_spoiler': hasSpoiler,
      'show_caption_above_media': showCaptionAboveMedia,
    }..removeWhere(_nullFilter);
  }
}
