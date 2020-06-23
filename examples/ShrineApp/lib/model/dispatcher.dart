typedef Command = void Function(String event, [int arg]);

class Dispatcher {

  Set<Command> commandListeners = Set();

  void scrollTo(int itemId) {
    _sendCommand("scrollToItem", itemId);
  }

  void openMenu() {
    _sendCommand("openMenu");
  }

  void openCart() {
    _sendCommand("openCart");
  }

  void closeCart() {
    _sendCommand("closeCart");
  }

  void back() {
    _sendCommand("back");
  }

  void _sendCommand(String command, [int arg]) {
    if (commandListeners != null) {
      commandListeners.forEach((l) => l(command, arg));
    }
  }

}