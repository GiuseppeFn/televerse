part of 'models.dart';

/// This object contains information about a poll.
class Poll {
  /// Unique poll identifier
  final String id;

  /// Poll question, 1-300 characters
  final String question;

  /// List of poll options
  final List<PollOption> options;

  /// Total number of users that voted in the poll
  final int totalVoterCount;

  /// True, if the poll is closed
  final bool isClosed;

  /// True, if the poll is anonymous
  final bool isAnonymous;

  /// Poll type, currently can be “regular” or “quiz”
  final PollType type;

  /// True, if the poll allows multiple answers
  final bool allowsMultipleAnswers;

  /// Optional. 0-based identifier of the correct answer option. Available only for polls in the quiz mode, which are closed, or was sent (not forwarded) by the bot or to the private chat with the bot.
  final int? correctOptionId;

  /// Optional. Text that is shown when a user chooses an incorrect answer or taps on the lamp icon in a quiz-style poll, 0-200 characters
  final String? explanation;

  /// Optional. Special entities like usernames, URLs, bot commands, etc. that appear in the explanation
  final List<MessageEntity>? explanationEntities;

  /// Optional. Amount of time in seconds the poll will be active after creation
  ///
  /// A handy [Duration] object is available as [openPeriodDuration] getter
  final int? openPeriod;

  /// Optional. Point in time (Unix timestamp) when the poll will be automatically closed
  ///
  /// A handy [DateTime] object is available as [closeDateTime] getter
  final int? closeDate;

  /// Optional. Special entities that appear in the question. Currently, only custom emoji entities are allowed in poll questions
  final List<MessageEntity>? questionEntities;

  /// Constructs a [Poll] object
  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVoterCount,
    required this.isClosed,
    required this.isAnonymous,
    required this.type,
    required this.allowsMultipleAnswers,
    this.correctOptionId,
    this.explanation,
    this.explanationEntities,
    this.openPeriod,
    this.closeDate,
    this.questionEntities,
  });

  /// Creates a [Poll] object from JSON object
  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id']!,
      question: json['question']!,
      options: (json['options'] as List<dynamic>)
          .map((x) => PollOption.fromJson(x as Map<String, dynamic>))
          .toList(),
      totalVoterCount: json['total_voter_count']!,
      isClosed: json['is_closed']!,
      isAnonymous: json['is_anonymous']!,
      type: PollType.fromJson(json['type']!),
      allowsMultipleAnswers: json['allows_multiple_answers']!,
      correctOptionId: json['correct_option_id'],
      explanation: json['explanation'],
      explanationEntities: (json['explanation_entities'] as List<dynamic>?)
          ?.map((x) => MessageEntity.fromJson(x as Map<String, dynamic>))
          .toList(),
      openPeriod: json['open_period'],
      closeDate: json['close_date'],
      questionEntities: (json['question_entities'] as List<dynamic>?)
          ?.map((x) => MessageEntity.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts a [Poll] object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((x) => x.toJson()).toList(),
      'total_voter_count': totalVoterCount,
      'is_closed': isClosed,
      'is_anonymous': isAnonymous,
      'type': type.toJson(),
      'allows_multiple_answers': allowsMultipleAnswers,
      'correct_option_id': correctOptionId,
      'explanation': explanation,
      'explanation_entities':
          explanationEntities?.map((x) => x.toJson()).toList(),
      'open_period': openPeriod,
      'close_date': closeDate,
      'question_entities': questionEntities?.map((x) => x.toJson()).toList(),
    }..removeWhere(_nullFilter);
  }

  /// The [Duration] object for [openPeriod]
  Duration? get openPeriodDuration =>
      openPeriod == null ? null : Duration(seconds: openPeriod!);

  /// The [DateTime] object for [closeDate]
  DateTime? get closeDateTime => closeDate?.toDateTime();
}
