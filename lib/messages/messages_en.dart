// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  get localeName => 'en';

  static m0(name) => "PayPal payment for ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "Aktuelles Guthaben:" : MessageLookupByLibrary.simpleMessage("Current credit:"),
    "Alle Transaktionen" : MessageLookupByLibrary.simpleMessage("All Transactions"),
    "Aufladung" : MessageLookupByLibrary.simpleMessage("Choose Credit"),
    "Beschreibung" : MessageLookupByLibrary.simpleMessage("Description"),
    "Betrag" : MessageLookupByLibrary.simpleMessage("Amount"),
    "Das ist nicht dein Benutzer? Dann logge dich bitte links beim letzten Punkt aus." : MessageLookupByLibrary.simpleMessage("This is not your user? Then please log out to the left at the last point."),
    "PayPal öffnen" : MessageLookupByLibrary.simpleMessage("Open PayPal Checkout"),
    "Transaktionen aktualisieren" : MessageLookupByLibrary.simpleMessage("Update transactions"),
    "Wert" : MessageLookupByLibrary.simpleMessage("Value"),
    "Zeit" : MessageLookupByLibrary.simpleMessage("Time"),
    "_paypalWindowTitle" : m0,
    "_userDefinedMessage" : MessageLookupByLibrary.simpleMessage("Custom"),
    "mit Kartennummer" : MessageLookupByLibrary.simpleMessage("with card number")
  };
}
