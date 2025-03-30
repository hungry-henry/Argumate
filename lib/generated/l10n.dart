// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Argumate`
  String get argumate {
    return Intl.message(
      'Argumate',
      name: 'argumate',
      desc: '',
      args: [],
    );
  }

  /// `Can't to convince others? Having trouble expressing?`
  String get help {
    return Intl.message(
      'Can\'t to convince others? Having trouble expressing?',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  /// `Choose a Scene: `
  String get chooseScene {
    return Intl.message(
      'Choose a Scene: ',
      name: 'chooseScene',
      desc: '',
      args: [],
    );
  }

  /// `Quarrel`
  String get quarrel {
    return Intl.message(
      'Quarrel',
      name: 'quarrel',
      desc: '',
      args: [],
    );
  }

  /// `Debate`
  String get debate {
    return Intl.message(
      'Debate',
      name: 'debate',
      desc: '',
      args: [],
    );
  }

  /// `Talk with boss`
  String get boss {
    return Intl.message(
      'Talk with boss',
      name: 'boss',
      desc: '',
      args: [],
    );
  }

  /// `Flirt`
  String get flirt {
    return Intl.message(
      'Flirt',
      name: 'flirt',
      desc: '',
      args: [],
    );
  }

  /// `Counter with teacher`
  String get teacher {
    return Intl.message(
      'Counter with teacher',
      name: 'teacher',
      desc: '',
      args: [],
    );
  }

  /// `more...`
  String get more {
    return Intl.message(
      'more...',
      name: 'more',
      desc: '',
      args: [],
    );
  }

  /// `Choose methods to input: `
  String get chooseInput {
    return Intl.message(
      'Choose methods to input: ',
      name: 'chooseInput',
      desc: '',
      args: [],
    );
  }

  /// `Screenshot for context`
  String get screenshot {
    return Intl.message(
      'Screenshot for context',
      name: 'screenshot',
      desc: '',
      args: [],
    );
  }

  /// `Copy msgs to input`
  String get copy {
    return Intl.message(
      'Copy msgs to input',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Voice call`
  String get call {
    return Intl.message(
      'Voice call',
      name: 'call',
      desc: '',
      args: [],
    );
  }

  /// `Debate with me, or copy messages context here`
  String get inputHint {
    return Intl.message(
      'Debate with me, or copy messages context here',
      name: 'inputHint',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
