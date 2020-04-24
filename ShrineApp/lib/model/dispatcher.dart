import 'package:flutter/widgets.dart';

typedef Command = void Function(String event, [int arg]);

class Dispatcher {

  static int counter = 0;

  final int _number;

  Dispatcher(): this._number = counter {
    debugPrint("CREATING DISPATCHER: $counter");
    counter++;
  }

  Set<Command> commandListeners = Set();

  void scrollTo(int itemId) {
    _sendCommand("scrollToItem", itemId);
  }

  void open() {
    _sendCommand("open");
  }

  void close() {
    _sendCommand("close");
  }

  void _sendCommand(String command, [int arg]) {
    debugPrint("Called on ${_number}");
    debugPrint("Command is $command");
    if (commandListeners != null) {
      commandListeners.forEach((l) => l(command, arg));
    } else {
      debugPrint("COMMAND LISTENER IS NULL");
    }
  }

}