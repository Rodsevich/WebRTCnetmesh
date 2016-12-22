import 'package:WebRTCnetmesh/WebRTCnetmesh_client.dart' show Command;

class ChatMessage extends Command{

  @override
  askForPermission() {
    return true;
  }

  ChatMessage(this.executor);

  @override
  execute() {
    appendMessage(this.arguments["message"], "message", this.arguments["user"]);
  }
}
