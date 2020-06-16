typedef Command = void Function(String event, [int arg]);

class Dispatcher {

  Set<Command> commandListeners = Set();

  void scrollTo(int itemId) {
    _sendCommand("scrollToItem", itemId);
  }

  void openCart() {
    _sendCommand("openCart");
  }

  void closeCart() {
    _sendCommand("closeCart");
  }

  void _sendCommand(String command, [int arg]) {
    if (commandListeners != null) {
      commandListeners.forEach((l) => l(command, arg));
    }
  }

}