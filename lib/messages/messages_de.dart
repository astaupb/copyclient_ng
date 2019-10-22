// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
// messages from the main program should be duplicated here with the same
// function name.

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

// ignore: unnecessary_new
final messages = new MessageLookup();

// ignore: unused_element
final _keepAnalysisHappy = Intl.defaultLocale;

// ignore: non_constant_identifier_names
typedef MessageIfAbsent(String message_str, List args);

class MessageLookup extends MessageLookupByLibrary {
  get localeName => 'de';

  static m0(name) => "PayPal Zahlung für ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "Aktuelles Guthaben:" : MessageLookupByLibrary.simpleMessage("Aktuelles Guthaben:"),
    "Alle Transaktionen" : MessageLookupByLibrary.simpleMessage("Alle Transaktionen"),
    "Aufladung" : MessageLookupByLibrary.simpleMessage("Aufladung"),
    "Beschreibung" : MessageLookupByLibrary.simpleMessage("Beschreibung"),
    "Betrag" : MessageLookupByLibrary.simpleMessage("Betrag"),
    "Das ist nicht dein Benutzer? Dann logge dich bitte links beim letzten Punkt aus." : MessageLookupByLibrary.simpleMessage("Das ist nicht dein Benutzer? Dann logge dich bitte links beim letzten Punkt aus."),
    "PayPal öffnen" : MessageLookupByLibrary.simpleMessage("PayPal öffnen"),
    "Transaktionen aktualisieren" : MessageLookupByLibrary.simpleMessage("Transaktionen aktualisieren"),
    "Wert" : MessageLookupByLibrary.simpleMessage("Wert"),
    "Zeit" : MessageLookupByLibrary.simpleMessage("Zeit"),
    "_paypalWindowTitle" : m0,
    "_userDefinedMessage" : MessageLookupByLibrary.simpleMessage("Benutzerdefiniert"),
    "mit Kartennummer" : MessageLookupByLibrary.simpleMessage("mit Kartennummer")
  };
}
