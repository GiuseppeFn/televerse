part of '../../televerse.dart';

/// Televerse
/// This class is used to create a new bot instance. The bot instance is used to send and receive messages.
///
/// You can use the [token] to create a new bot instance. You can also pass a [fetcher] to the constructor. The fetcher is used to fetch updates from the Telegram servers. By default, the bot uses long polling to fetch updates. You can also use webhooks to fetch updates.
///
/// Create a new bot instance:
/// ```dart
/// import 'package:televerse/televerse.dart';
///
/// void main() {
///  final bot = Bot("YOUR_BOT_TOKEN");
///  bot.start();
/// }
/// ```
///
class Bot {
  /// API Scheme
  final APIScheme _scheme;

  /// The current bot instance.
  static late Bot _instance;

  /// Base URL of the Telegram Bot API.
  final String _baseURL;

  /// A flag that indicates whether the Bot API is running locally or not.
  final bool isLocal;

  /// Options to configure the logger.
  final LoggerOptions? _loggerOptions;

  /// Handler for unexpected errors.
  FutureOr<void> Function(BotError error)? _onError;

  /// The timeout duration for the requests.
  ///
  /// This is used to set the timeout duration for the requests. When the timeout duration is reached, the request will be cancelled.
  final Duration? timeout;

  /// Get the bot instance.
  ///
  /// This getter returns the bot instance. You can use this to access the bot instance from anywhere in your code.
  ///
  /// Notes:
  ///   - If you try to access this getter before creating a bot instance, it will throw an error.
  ///   - The instance will be the last created bot instance.
  ///   - DO NOT use this getter to create a bot instance. Use the [Bot] constructor instead. This getter is only used to access the bot instance.
  static Bot get instance {
    try {
      return _instance;
    } catch (err) {
      throw TeleverseException(
        "Bot instance not found. ",
        description: "Create a Bot instance with a token first.",
        type: TeleverseExceptionType.botNotInitialized,
      );
    }
  }

  /// Raw API - gives you access to all the methods of Telegram Bot API.
  ///
  /// This getter returns the [RawAPI] instance. You can use this to access the raw API instance from anywhere in your code.
  ///
  /// For example, you can use the [RawAPI] instance to send a message to a chat:
  /// ```dart
  /// bot.api.sendMessage(ChatID(123456789), "Hello World!");
  /// ```
  ///
  RawAPI get api {
    if (isLocal) {
      return RawAPI.local(
        token,
        baseUrl: _baseURL,
        scheme: _scheme,
        loggerOptions: _loggerOptions,
        timeout: timeout,
      );
    }
    return RawAPI(
      token,
      loggerOptions: _loggerOptions,
      timeout: timeout,
    );
  }

  /// The fetcher - used to fetch updates from the Telegram servers.
  late final Fetcher fetcher;

  /// The bot token.
  final String token;

  /// Create a new bot instance.
  ///
  /// To create a new bot instance, you need to pass the bot token. You can also pass a [fetcher] to the constructor. The fetcher is used to fetch updates from the Telegram servers. By default, the bot uses long polling to fetch updates. You can also use webhooks to fetch updates.
  ///
  /// ## Using Local Bot API Server
  /// You can use the [Bot] class to create a bot instance that listens to a local Bot API server. Use the [Bot.local] constructor to create a bot instance that listens to a local Bot API server.
  ///
  /// You can pass the [baseURL] parameter to the constructor to specify the base URL of the Telegram Bot API. By default, the base URL is `api.telegram.org`. This parameter will be used to create the [RawAPI] instance that points to your local Bot API server.
  /// If you're running the Bot API server locally, you should pass the [baseURL] and the [scheme] parameters to the constructor.
  Bot(
    this.token, {
    Fetcher? fetcher,
    String baseURL = RawAPI.defaultBase,
    APIScheme scheme = APIScheme.https,
    LoggerOptions? loggerOptions,
    this.timeout,
  })  : _baseURL = baseURL,
        isLocal = baseURL != RawAPI.defaultBase,
        _loggerOptions = loggerOptions,
        _scheme = scheme {
    this.fetcher = fetcher ?? LongPolling();
    this.fetcher.setApi(api);
    _instance = this;

    getMe().then(_ignore).catchError(_thenHandleGetMeError);
  }

  /// Function to ignore things.
  void _ignore(_) {}

  /// Handles the error in initial `getMe` call
  FutureOr<Null> _thenHandleGetMeError(Object err, StackTrace st) async {
    if (_onError != null) {
      final botErr = BotError(err, st);
      await _onError!(botErr);
    } else if (err is DioException) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout) {
        throw TeleverseException.timeoutException(st, timeout!);
      }
    } else {
      throw err;
    }
  }

  /// Televerse local constructor. This constructor is used to create a bot instance that listens to a local Bot API server.
  ///
  /// [token] - Bot token.
  ///
  /// [baseURL] - Base URL of the Telegram Bot API. By default, the base URL is `localhost:8081`. This parameter will be used to create the [RawAPI] instance that points to your local Bot API server.
  ///
  /// [fetcher] - The fetcher - used to fetch updates from the Telegram servers. By default, the bot uses long polling to fetch updates. You can also use webhooks to fetch updates.
  ///
  /// [scheme] - The scheme of the Telegram Bot API. By default, the scheme is `APIScheme.http`.
  ///
  /// ## Note
  /// The Bot API server source code is available at [telegram-bot-api](https://github.com/tdlib/telegram-bot-api). You can run it locally and send the requests to your own server instead of ```https://api.telegram.org```.
  ///
  /// If you switch to a local Bot API server, your bot will be able to:
  /// - Download files without a size limit.
  /// - Upload files up to 2000 MB.
  /// - Upload files using their local path and the file URI scheme.
  /// - Use an HTTP URL for the webhook.
  /// - Use any local IP address for the webhook.
  /// - Use any port for the webhook.
  /// - Set max_webhook_connections up to 100000.
  /// - Receive the absolute local path as a value of the file_path field without the need to download the file after a getFile request.
  ///
  /// Learn to setup Local Bot API Server here: https://github.com/tdlib/telegram-bot-api
  factory Bot.local(
    String token, {
    Fetcher? fetcher,
    bool sync = false,
    String baseURL = "localhost:8081",
    APIScheme scheme = APIScheme.http,
    LoggerOptions? loggerOptions,
    Duration? timeout,
  }) {
    print('Using local Bot API server at $baseURL');
    return Bot(
      token,
      fetcher: fetcher,
      baseURL: baseURL,
      scheme: scheme,
      loggerOptions: loggerOptions,
      timeout: timeout,
    );
  }

  /// List of pending calls
  final List<_PendingCall> _pendingCalls = [];

  /// Whether _me is filled or not
  _GetMeStatus _getMeStatus = _GetMeStatus.notInitiated;

  /// Whether the `Bot.me` is filled
  bool get initialized => _getMeStatus == _GetMeStatus.completed;

  /// Information about the bot.
  late User _me;

  /// Get information about the bot.
  ///
  /// This getter returns the bot information. You can use this to access the bot information from anywhere in your code. This getter will be automatically set when the bot starts.
  /// If you try to access this getter before creating a bot instance, it will throw an error.
  User get me {
    try {
      return _me;
    } catch (err, stack) {
      throw TeleverseException(
        "Bot information not found.",
        description:
            "This happens when the initial getMe request is not completed. You can call `bot.getMe` method to set this property.",
        stackTrace: stack,
        type: TeleverseExceptionType.requestFailed,
      );
    }
  }

  /// Get information about the bot.
  ///
  /// This will also set `bot.me`. If by any chance the request is failed,
  /// this will throw a TeleverseException with the details about the exception.
  ///
  /// Note: As of now this won't be handled in `onError` handler.
  Future<User> getMe() async {
    try {
      if (initialized) {
        return _me;
      }
      _getMeStatus = _GetMeStatus.pending;
      _me = await api.getMe();
      _getMeStatus = _GetMeStatus.completed;

      if (_pendingCalls.isNotEmpty) {
        for (final fn in _pendingCalls) {
          fn.call();
        }
      }

      return _me;
    } catch (err, stack) {
      final exception = TeleverseException.getMeRequestFailed(err, stack);
      throw exception;
    }
  }

  /// Whether the function is async or not.
  /// Thanks to StackOverflow answer: https://stackoverflow.com/a/63109983/10006183
  bool _checkSync(Function fn) {
    if (fn is Future Function(Never)) return true;
    return false;
  }

  /// Emit new update into the stream.
  void _onUpdate(Update update) async {
    final sub = _handlerScopes.reversed.where((scope) {
      return scope.types.contains(update.type);
    }).toList();
    int len = sub.length;
    for (int i = 0; i < len; i++) {
      final context = Context(this, update: update);

      if (sub[i].isConversation && sub[i].predicate(context)) {
        break;
      }

      if (sub[i].handler == null) continue;

      if (sub[i].special) {
        if (sub[i].isRegExp) {
          final text = context.msg?.text ?? "";
          if (sub[i].pattern != null) {
            context._matches = sub[i].pattern!.allMatches(text).toList();
          }
        }
      }

      if (sub[i].predicate(context)) {
        if (_checkSync(sub[i].handler!)) {
          try {
            await ((sub[i].handler!(context)) as Future);
          } catch (err, stack) {
            if (_onError != null) {
              final botErr = BotError(err, stack, ctx: context);
              await _onError!(botErr);
            } else {
              rethrow;
            }
          }
        } else {
          try {
            sub[i].handler!(context);
          } catch (err, stack) {
            if (_onError != null) {
              final botErr = BotError(err, stack, ctx: context);
              await _onError!(botErr);
            } else {
              rethrow;
            }
          }
        }
        break;
      }
    }
  }

  /// List of Handler Scopes
  final List<HandlerScope> _handlerScopes = [];

  /// To manually handle updates without fetcher
  ///
  /// This method is useful when you want to use a custom webhook server instead of the default one provided by Televerse,
  /// or to use in a cloud function.
  /// use Update.fromJson(json) to convert the json to an update.
  void handleUpdate(Update update) => _onUpdate(update);

  /// Start polling for updates.
  ///
  /// This method starts polling for updates. It will automatically start the fetcher.
  ///
  /// You can pass a [handler] to the method. The handler will be called when a message is received that starts with the `/start` command.
  ///
  /// Optional [isServerless] flag can be passed to the method. If you set this flag to true, the bot will not start the fetcher.
  Future<void> start([
    Handler? handler,
    bool isServerless = false,
  ]) async {
    // Registers a handler to listen for /start command
    if (handler != null) {
      command("start", handler);
    }
    if (isServerless) return;
    fetcher.onUpdate().listen(
      _onUpdate,
      onDone: () {
        _onStop.call();
      },
    );
    try {
      return await fetcher.start();
    } catch (err, stack) {
      if (_onError != null) {
        fetcher.stop();
        final botErr = BotError(err, stack);
        await _onError!(botErr);
        return fetcher.start();
      } else {
        rethrow;
      }
    }
  }

  /// Stop listening for updates.
  Future<void> stop({
    bool shouldCloseHttpClient = true,
  }) {
    if (shouldCloseHttpClient) {
      api.closeClient();
    }
    return fetcher.stop();
  }

  /// Stream of [Update] objects.
  ///
  /// This getter returns a stream of [Update] objects. You can use this to listen to incoming updates from Telegram servers.
  Stream<Update> get updatesStream {
    return fetcher.onUpdate();
  }

  /// Registers a callback for a command.
  /// The command must be without the leading slash.
  ///
  /// For example, to register a callback for the `/start` command, you would
  /// call `command('start', callback)`.
  ///
  /// The callback will be called when a message is received that starts with
  /// the command.
  ///
  /// Example:
  /// ```dart
  /// bot.command('start', (ctx) {
  ///   ctx.reply('Hello!');
  /// });
  /// ```
  ///
  /// This will reply "Hello!" to any message that starts with `/start`.
  Future<void> command(
    Pattern command,
    Handler callback,
  ) async {
    if (initialized) {
      final scope = HandlerScope(
        isCommand: true,
        handler: callback,
        types: [UpdateType.message],
        predicate: (ctx) {
          if (ctx.msg?.text == null) return false;
          if (command is RegExp) {
            return command.hasMatch(ctx.msg?.text ?? "");
          } else if (command is String) {
            final firstTerm = ctx.msg?.text!.split(' ').first;
            final suffix = me.username != null ? '@${me.username}' : '';
            return firstTerm == '/$command' || firstTerm == '/$command$suffix';
          }
          return false;
        },
      );
      _handlerScopes.add(scope);
      return;
    }

    if (_getMeStatus == _GetMeStatus.pending) {
      _pendingCalls.add(
        _PendingCall(
          fn: this.command,
          params: [command, callback],
        ),
      );
    }
  }

  /// Registers a Handler Scope to listen to matching callback query.
  void _internalCallbackQueryRegister(
    Pattern data,
    Handler callback, {
    String? name,
  }) {
    final scope = HandlerScope(
      name: name,
      handler: callback,
      types: [UpdateType.callbackQuery],
      predicate: (ctx) {
        if (ctx.callbackQuery?.data == null) return false;
        if (data is RegExp) {
          return data.hasMatch(ctx.callbackQuery?.data ?? "");
        } else if (data is String) {
          return ctx.callbackQuery?.data == data;
        }
        return false;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for a callback query.
  ///
  /// The callback will be called when a callback query is received that has
  /// the specified data.
  ///
  /// Example:
  /// ```dart
  /// bot.callbackQuery('start', (ctx) {
  ///   ctx.answer('Hello!');
  /// });
  /// ```
  ///
  /// This will answer "Hello!" to any callback query that has the data "start".
  ///
  ///
  void callbackQuery(
    Pattern data,
    Handler callback, {
    @Deprecated("Use the 'data' parameter instead.") RegExp? regex,
  }) {
    return _internalCallbackQueryRegister(data, callback);
  }

  /// Registers a callback for particular chat types.
  /// The callback will be called when a message is received that is from a
  /// chat of the specified type.
  ///
  /// You can specify chat type by passing a [ChatType] to the [type] parameter.
  ///
  /// Example:
  /// ```dart
  /// bot.chatType(ChatType.private, (ctx) {
  ///  ctx.reply('Hello in private chat!');
  /// });
  /// ```
  ///
  /// This will reply "Hello in private chat!" to any message that is from a
  /// private chat.
  ///
  /// If you want to register a callback for multiple chat types, you can use
  /// the [chatTypes] method.
  void chatType(
    ChatType type,
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return ctx.message?.chat.type == type;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for multiple chat types.
  /// The callback will be called when a message is received that is from one of
  /// the specified chat types.
  ///
  /// You can specify chat types by passing a list of [ChatType]s to the [types]
  /// parameter.
  ///
  /// Example:
  /// ```dart
  /// bot.chatTypes([ChatType.private, ChatType.group], (ctx) {
  /// ctx.reply('Hello in private chat or group!');
  /// });
  /// ```
  ///
  /// This will reply "Hello in private chat or group!" to any message that is
  /// from a private chat or a group.
  void chatTypes(
    List<ChatType> types,
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return types.contains(ctx.message?.chat.type);
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for a message that matches the specified filter.
  ///
  /// The callback will be called when a message is received that matches the
  /// specified filter.
  ///
  /// This method accepts a predicate function that takes a [Context] as
  /// a parameter and returns a boolean. If the function returns true, the
  /// callback will be called.
  ///
  /// Example:
  /// ```dart
  /// bot.filter((ctx) {
  ///   return (ctx.message.photo?.last.fileSize ?? 0) > 1000000;
  /// }, (ctx) async {
  ///   await ctx.reply('Wow, that\'s a big photo!');
  /// });
  /// ```
  void filter(
    bool Function(Context ctx) predicate,
    Handler callback, {
    String? name,
  }) {
    final scope = HandlerScope(
      name: name,
      handler: callback,
      types: UpdateType.values,
      predicate: predicate,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for a message that contains a text.
  /// The callback will be called when a message is received that contains a
  /// particular text.
  ///
  /// Example:
  /// ```dart
  /// bot.text('I love Televerse', (ctx) {
  ///  ctx.reply('I love you too!');
  /// });
  /// ```
  void text(
    String text,
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return ctx.message?.text == text;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for a message that contains a text that matches the
  /// specified regular expression.
  /// The callback will be called when a message is received that contains a
  /// text that matches the specified regular expression.
  ///
  /// The regular expression must be a valid Dart regular expression.
  ///
  /// Example:
  /// ```dart
  /// bot.hears(r'Hello, (.*)!', (ctx) {
  ///   ctx.reply('Hello, ${ctx.matches![1]}!');
  /// });
  /// ```
  ///
  /// This will reply "Hello, <name>!" to any message that contains a text that
  /// matches the regular expression `Hello, (.*)!`.
  void hears(
    RegExp exp,
    Handler callback,
  ) {
    final scope = HandlerScope(
      pattern: exp,
      isRegExp: true,
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return exp.hasMatch(ctx.message?.text ?? '');
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for inline queries.
  ///
  /// The callback will be called when an inline query with the specified query is received.
  void inlineQuery(
    Pattern query,
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.inlineQuery,
      ],
      predicate: (ctx) {
        final queryText = ctx.inlineQuery?.query ?? '';
        if (query is RegExp) {
          return query.hasMatch(queryText);
        }
        if (query is String) {
          return RegExp(query).hasMatch(queryText);
        }
        return false;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for the `/settings` command.
  Future<void> settings(Handler handler) {
    return command("settings", handler);
  }

  /// Registers a callback for the `/help` command.
  Future<void> help(Handler handler) {
    return command("help", handler);
  }

  /// Registers a callback for any unexpected error.
  ///
  /// The `err` parameter will be an instance of [BotError].
  ///
  /// The handler will be called whenever one of the following exceptions are thrown,
  /// or any unexpected error is thrown:
  ///  - [TelegramException]
  ///  - [LongPollingException]
  ///  - [TeleverseException]
  ///
  /// When a [LongPollingException] is thrown, the fetcher will be stopped and
  /// waits for the [handler] to finish executing. After that, the fetcher will
  /// be started again.
  ///
  /// Note: you DON'T have to manually wait for the [ResponseParameters.retryAfter] duration.
  /// The fetcher will automatically wait for the duration and start polling again.
  void onError(
    void Function(BotError err) handler,
  ) {
    _onError = handler;
    fetcher.onError(handler);
  }

  /// A filter that matches messages that contains the specified entity type.
  /// Optionally, you can pass the [content] parameter to match messages that
  /// contains the specified entity type and the specified content.
  ///
  /// This acts as a shortcut for the [entity] method and [onHashtag] methods.
  bool _internalEntityMatcher({
    required Context context,
    required MessageEntityType type,
    String? content,
    bool shouldMatchCaptionEntities = false,
  }) {
    List<MessageEntity>? entities = context.message?.entities;
    if (shouldMatchCaptionEntities) {
      entities = entities ?? context.message?.captionEntities;
    }
    bool hasMatch = entities?.any((element) => element.type == type) ?? false;

    if (content != null) {
      String value;
      switch (type) {
        case MessageEntityType.hashtag:
          value = "#$content";
          break;
        case MessageEntityType.mention:
          value = "@$content";
          break;
        default:
          value = content;
      }
      if (entities == null) return false;
      hasMatch = entities.any((element) {
        if (element.type == type) {
          if (!shouldMatchCaptionEntities) {
            return context.message?.text!.substring(
                  element.offset,
                  element.offset + element.length,
                ) ==
                value;
          } else {
            return context.message?.caption!.substring(
                  element.offset,
                  element.offset + element.length,
                ) ==
                value;
          }
        }
        return false;
      });
    }

    return hasMatch;
  }

  /// Registers a callback for messages that contains the specified entity type.
  ///
  /// Pass the `shouldMatchCaptionEntities` parameter to match entities in the
  /// caption of a message. Such as a photo or video message.
  ///
  /// By default, this method will ONLY match entities in the message text.
  void entity(
    MessageEntityType type,
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
  }) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return _internalEntityMatcher(
          context: ctx,
          type: type,
          shouldMatchCaptionEntities: shouldMatchCaptionEntities,
        );
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for messages that contains the specified entity types.
  /// The callback will be called when a message is received that contains the
  /// specified entity types.
  ///
  /// Pass the `shouldMatchCaptionEntities` parameter to match entities in the
  /// caption of a message. Such as a photo or video message.
  ///
  /// By default, this method will ONLY match entities in the message text.
  void entities(
    List<MessageEntityType> types,
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
  }) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        List<MessageEntity>? entities = ctx.message?.entities;
        if (shouldMatchCaptionEntities) {
          entities = entities ?? ctx.message?.captionEntities;
        }

        bool hasMatch = types.every(
          (element) => entities!.any(
            (e) => e.type == element,
          ),
        );

        return hasMatch;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers callback for the [ChatMemberUpdated] events
  void _internalChatMemberUpdatedHandling({
    required Handler callback,
    ChatMemberStatus? oldStatus,
    ChatMemberStatus? newStatus,
  }) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatMember,
      ],
      predicate: (ctx) {
        final os = ctx.chatMemberUpdated?.oldChatMember.status;
        final ns = ctx.chatMemberUpdated?.newChatMember.status;
        if (oldStatus == null && newStatus == null) {
          return true;
        }
        if (oldStatus != null && newStatus != null) {
          if (os == oldStatus && ns == newStatus) {
            return true;
          }
        }
        if (oldStatus != null && os == oldStatus) {
          return true;
        }
        if (newStatus != null && ns == newStatus) {
          return true;
        }
        return false;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for the [Update.chatMember] events.
  ///
  /// If you want to receive the Chat Member updates, you must explicitly specify
  /// the `UpdateType.chatMember` in the [LongPolling.allowedUpdates] property.
  ///
  /// You can optionally specify [ChatMemberStatus] to [oldStatus] and [newStatus]
  /// filter to only receive updates for a specific status.
  void chatMember(
    Handler callback, {
    ChatMemberStatus? oldStatus,
    ChatMemberStatus? newStatus,
  }) {
    return _internalChatMemberUpdatedHandling(
      callback: callback,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );
  }

  /// Registers a callback for the [Update.myChatMember] events.
  ///
  /// You can optionally specify [ChatMemberStatus] to [oldStatus] and [newStatus]
  /// filter to only receive updates for a specific status.
  void myChatMember({
    required Handler callback,
    ChatMemberStatus? oldStatus,
    ChatMemberStatus? newStatus,
  }) {
    return _internalChatMemberUpdatedHandling(
      callback: callback,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );
  }

  /// Registers a callback for the [Update.poll] events.
  void poll(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.poll,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for the [Update.pollAnswer] events.
  ///
  /// Optionally pass the [pollId] parameter to only receive updates for a specific poll.
  void pollAnswer(
    Handler callback, {
    String? pollId,
  }) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.pollAnswer,
      ],
      predicate: (ctx) {
        if (pollId == null) return true;
        return ctx.pollAnswer?.pollId == pollId;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for the [Update.chosenInlineResult] events.
  /// The callback will be called when a chosen inline result is received.
  void chosenInlineResult(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chosenInlineResult,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for the [Update.chatJoinRequest] events.
  ///
  /// The callback will be called when a chat join request is received.
  void chatJoinRequest(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatJoinRequest,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for Shipping Query events.
  void shippingQuery(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.shippingQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for Pre Checkout Query events.
  void preCheckoutQuery(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.preCheckoutQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Sets up a callback for when a message with URL is received.
  void onURL(
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
  }) {
    return entity(
      MessageEntityType.url,
      callback,
      shouldMatchCaptionEntities: shouldMatchCaptionEntities,
    );
  }

  /// Sets up a callback for when a message with email is received.
  void onEmail(
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
  }) {
    return entity(
      MessageEntityType.email,
      callback,
      shouldMatchCaptionEntities: shouldMatchCaptionEntities,
    );
  }

  /// Sets up a callback for when a message with phone number is received.
  void onPhoneNumber(
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
  }) {
    return entity(
      MessageEntityType.phoneNumber,
      callback,
      shouldMatchCaptionEntities: shouldMatchCaptionEntities,
    );
  }

  /// Sets up a callback for when a message with hashtag is received.
  void onHashtag(
    Handler callback, {
    bool shouldMatchCaptionEntities = false,
    String? hashtag,
  }) {
    if (hashtag == null) {
      return entity(
        MessageEntityType.hashtag,
        callback,
        shouldMatchCaptionEntities: shouldMatchCaptionEntities,
      );
    }

    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        return _internalEntityMatcher(
          context: ctx,
          type: MessageEntityType.hashtag,
          content: hashtag,
          shouldMatchCaptionEntities: shouldMatchCaptionEntities,
        );
      },
    );

    _handlerScopes.add(scope);
  }

  /// Sets up a callback for when a mention is occurred.
  /// Optionally, you can pass the [username] parameter or [userId] parameter to
  /// only receive updates for a specific user.
  ///
  /// [username] - The username of the user. Don't pass the leading '@' character.
  ///
  /// [userId] - The ID of the user.
  ///
  /// When the [username] parameter is passed, the callback will be called when a
  /// [MessageEntityType.mention] entity is occurred with the specified username.
  ///
  /// When the [userId] parameter is passed, the callback will be called when a
  /// [MessageEntityType.textMention] entity is occurred with the specified user ID.
  ///
  /// That is you don't have to setup a different callback for [MessageEntityType.mention]
  /// and [MessageEntityType.textMention] entities. (Well, you can if you want to.)
  void onMention(
    Handler callback, {
    String? username,
    int? userId,
  }) {
    if (username == null && userId == null) {
      return entity(
        MessageEntityType.mention,
        callback,
      );
    }
    if (username != null) {
      final scope = HandlerScope(
        handler: callback,
        types: [
          UpdateType.message,
        ],
        predicate: (ctx) {
          return _internalEntityMatcher(
            context: ctx,
            type: MessageEntityType.mention,
            content: username,
          );
        },
      );
      return _handlerScopes.add(scope);
    }

    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) {
        List<MessageEntity>? entities = ctx.message?.entities;
        bool hasMatch = entities?.any((element) {
              if (element.type == MessageEntityType.textMention) {
                return element.user?.id == userId;
              }
              return false;
            }) ??
            false;

        return hasMatch;
      },
    );

    _handlerScopes.add(scope);
  }

  /// This method sets up a callback when the bot is mentioned.
  ///
  /// This method possibly returns a [Future] if the bot information is not available
  /// when the method is called. If the bot information is not available, the method
  /// will fetch the bot information using the [RawAPI.getMe] method and then setup the callback.
  ///
  ///
  Future<void> whenMentioned(
    Handler callback,
  ) async {
    if (initialized) {
      return onMention(
        callback,
        username: me.username,
      );
    }
    if (_getMeStatus == _GetMeStatus.pending) {
      _pendingCalls.add(
        _PendingCall(
          fn: whenMentioned,
          params: [callback],
        ),
      );
    }
  }

  /// Registers a callback for all Message updates
  void onMessage(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.message,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Edited Message updates
  void onEditedMessage(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.editedMessage,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Channel Post updates
  void onChannelPost(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.channelPost,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Edited Channel Post updates
  void onEditedChannelPost(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.editedChannelPost,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Inline Query updates
  void onInlineQuery(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.inlineQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Chosen Inline Result updates
  void onChosenInlineResult(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chosenInlineResult,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Callback Query updates
  void onCallbackQuery(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.callbackQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Shipping Query updates
  void onShippingQuery(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.shippingQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Pre Checkout Query updates
  void onPreCheckoutQuery(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.preCheckoutQuery,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired for all successful payments
  void onSuccessfulPayment(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.successfulPayment != null,
    );
  }

  /// Registers a callback for all Poll updates
  void onPoll(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.poll,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Poll Answer updates
  void onPollAnswer(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.pollAnswer,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all My Chat Member updates
  void onMyChatMember(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.myChatMember,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Chat Member updates
  void onChatMember(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatMember,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for all Chat Join Request updates
  void onChatJoinRequest(Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatJoinRequest,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// On Stop Handler
  void Function() _onStop = () {};

  /// Registers a callback when the the bot is stopped.
  ///
  /// This can be used to clean up resources.
  void onStop(void Function() callback) {
    _onStop = callback;
  }

  /// Internal method to handle sub message handlers
  void _internalSubMessageHandler(
    Handler callback,
    bool Function(Context) predicate, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
    String? name,
  }) {
    final scope = HandlerScope(
      name: name,
      handler: callback,
      types: [
        if (includeChannelPosts || onlyChannelPosts) UpdateType.channelPost,
        if (!onlyChannelPosts) UpdateType.message,
      ],
      predicate: (ctx) {
        return predicate(ctx);
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for messages that contain an audio.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onAudio(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.audio != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a document.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onDocument(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.document != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a photo.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onPhoto(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.photo != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a sticker.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onSticker(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.sticker != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a video.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onVideo(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.video != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a video note.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onVideoNote(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.videoNote != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a voice note.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onVoice(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.voice != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a contact.
  void onContact(
    Handler callback,
  ) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.contact != null,
    );
  }

  /// Registers a callback for messages that contain a dice.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onDice(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.dice != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a game.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onGame(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.game != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a poll.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onPollMessage(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.poll != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contain a venue.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onVenue(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.venue != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that contains a location.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onLocation(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.location != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for messages that is a live location update.
  void onLiveLocation(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) =>
          ctx.message?.location != null &&
          ctx.message?.location!.livePeriod != null,
    );
  }

  /// Registers a callback for new chat title service messages.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onNewChatTitle(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.newChatTitle != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for new chat photo service messages.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onNewChatPhoto(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.newChatPhoto != null,
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for delete chat photo service messages.
  void onDeleteChatPhoto(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) =>
          ctx.message?.deleteChatPhoto != null && ctx.message!.deleteChatPhoto!,
    );
  }

  /// Registers a callback for pinned message service messages.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onPinnedMessage(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.pinnedMessage != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for a user is shared to the bot
  void onUsrShared(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.usersShared != null,
    );
  }

  /// Registers a callback for a chat is shared to the bot
  void onChatShared(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.chatShared != null,
    );
  }

  /// Registers a callback for a video chat is scheduled
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void whenVideoChatScheduled(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.videoChatScheduled != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for a video chat is started
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void whenVideoChatStarted(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.videoChatStarted != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback for a video chat is ended
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void whenVideoChatEnded(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.videoChatEnded != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback to be fired when new participants are invited to a video chat
  void whenVideoChatParticipantsInvited(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.videoChatParticipantsInvited != null,
    );
  }

  /// Registers a callback to be fired when a forum topic is created
  void onForumTopicCreated(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.forumTopicCreated != null,
    );
  }

  /// Registers a callback to be fired when a forum topic is edited
  void onForumTopicEdited(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.forumTopicEdited != null,
    );
  }

  /// Registers a callback to be fired when a forum topic is closed
  void onForumTopicClosed(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.forumTopicClosed != null,
    );
  }

  /// Registers a callback to be fired when a forum topic is reopened
  void onForumTopicReopened(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.forumTopicReopened != null,
    );
  }

  /// Registers a callback to be fired when data sent from a web app is received
  void onWebAppData(Handler callback) {
    return _internalSubMessageHandler(
      callback,
      (ctx) => ctx.message?.webAppData != null,
    );
  }

  /// Registers a callback to be fired when an animation is sent
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onAnimation(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.animation != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback to be fired when a text message is received.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onText(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.text != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Registers a callback to be fired when a message with caption is received.
  ///
  /// By default, this method will only match messages that are sent in private chats / groups.
  /// You can pass the [includeChannelPosts] parameter to match messages that are sent in channels.
  ///
  /// Alternatively, you can pass the [onlyChannelPosts] parameter to only match messages that are sent in channels.
  void onCaption(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.caption != null;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
    );
  }

  /// Attach an Inline Menu.
  ///
  /// This method will make the menu handlers to be called when the menu buttons are pressed.
  void attachMenu(TeleverseMenu menu) {
    if (menu is InlineMenu) {
      int rows = menu._buttons.length;
      for (int i = 0; i < rows; i++) {
        int cols = menu._buttons[i].length;
        for (int j = 0; j < cols; j++) {
          if (menu._buttons[i][j].hasHandler) {
            final data =
                menu._buttons[i][j].getData() ?? menu._buttons[i][j].text;
            _internalCallbackQueryRegister(
              data,
              menu._buttons[i][j].handler as Handler,
              name: "${menu.name}-$data",
            );
          }
        }
      }
    }
    if (menu is KeyboardMenu) {
      int rows = menu._buttons.length;
      for (int i = 0; i < rows; i++) {
        int cols = menu._buttons[i].length;
        for (int j = 0; j < cols; j++) {
          final text = menu._buttons[i][j].text;
          final name = "${menu.name}-$text";

          final action = menu._buttons[i][j].handler as Handler;
          switch (menu._buttons[i][j].runtimeType) {
            case _KeyboardMenuTextButton:
              _internalSubMessageHandler(
                action,
                (ctx) => ctx.message?.text == text,
                name: name,
              );
              break;
            case _KeyboardMenuRequestContactButton:
              _internalSubMessageHandler(
                action,
                (ctx) => ctx.message?.contact != null,
                name: name,
              );
              break;
            case _KeyboardMenuRequestLocationButton:
              _internalSubMessageHandler(
                action,
                (ctx) => ctx.message?.location != null,
                name: name,
              );
              break;
            case _KeyboardMenuRequestUsersButton:
              _internalSubMessageHandler(
                action,
                (ctx) => ctx.message?.usersShared != null,
                name: name,
              );
          }
        }
      }
    }
  }

  /// Remove an Inline Menu.
  void removeMenu(TeleverseMenu menu) {
    _handlerScopes.removeWhere(
      (scope) => scope.name?.startsWith(menu.name) ?? false,
    );
  }

  /// Next step handler
  void setNextStep(Message msg, Handler callback) {
    final scopeName = "next-step-${msg.messageId}";
    bool isNextMessage(int? messageId) {
      return messageId == msg.messageId + 1 || messageId == msg.messageId + 2;
    }

    filter(
      (ctx) {
        return ctx.message?.chat.id == msg.chat.id &&
            isNextMessage(ctx.message?.messageId);
      },
      (ctx) async {
        await callback(ctx);
        _handlerScopes.removeWhere((scope) => scope.name == scopeName);
      },
      name: scopeName,
    );
  }

  /// Register a callback for any command.
  ///
  /// This method will match any command that is sent to the bot.
  void onCommand(
    Handler callback, {
    bool includeChannelPosts = false,
    bool onlyChannelPosts = false,
    String? name,
  }) {
    return _internalSubMessageHandler(
      callback,
      (ctx) {
        return ctx.message?.entities?.any((element) {
              return element.type == MessageEntityType.botCommand &&
                  element.offset == 0;
            }) ??
            false;
      },
      includeChannelPosts: includeChannelPosts,
      onlyChannelPosts: onlyChannelPosts,
      name: name,
    );
  }

  /// Register a callback when a reaction to a message was changed by a user.
  void onMessageReaction(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.messageReaction,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Reactions to a message with anonymous reactions were changed.
  void onMessageReactionCount(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.messageReactionCount,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback for when the chat was boosted.
  ///
  /// The bot must be an administrator in the chat for this to work.
  void onChatBoosted(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatBoost,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired when the chat boost was removed.
  ///
  /// The bot must be an administrator in the chat for this to work.
  void onChatBoostRemoved(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.chatBoostRemoved,
      ],
      predicate: (ctx) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired when a user reacts given emoji to a message.
  void whenReacted(String emoji, Handler callback) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.messageReaction,
      ],
      predicate: (ctx) {
        return ctx.messageReaction?.newReaction.any((ReactionType el) {
              return el is ReactionTypeEmoji && el.emoji == emoji;
            }) ??
            false;
      },
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired when a connection of the bot with a business account is made.
  void onBusinessConnection(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.businessConnection,
      ],
      predicate: (_) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers callback to be fired when a new message is received in a business account connected to the bot.
  void onBusinessMessage(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.businessMessage,
      ],
      predicate: (_) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired when a business message is edited.
  void onBusinessMessageEdited(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.editedBusinessMessage,
      ],
      predicate: (_) => true,
    );

    _handlerScopes.add(scope);
  }

  /// Registers a callback to be fired when a business message is deleted.
  void onBusinessMessageDeleted(
    Handler callback,
  ) {
    final scope = HandlerScope(
      handler: callback,
      types: [
        UpdateType.deletedBusinessMessages,
      ],
      predicate: (_) => true,
    );

    _handlerScopes.add(scope);
  }
}
