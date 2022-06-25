class ChatRoomModel {
  String? chatroomid;
  Map<dynamic, dynamic>? participants;
  String? lastMessage;
  bool? read;
  String? timeStamp;
  String? idFrom;
  String? idTo;
  int? count;

  ChatRoomModel({this.chatroomid, this.participants, this.lastMessage});

  ChatRoomModel.fromMap(Map<dynamic, dynamic> map) {
    chatroomid = map["chatroomid"];
    participants = map["participants"];
    lastMessage = map["lastmessage"];
    read = map["read"];
    timeStamp = map["time"];
    count = map["count"];
    idFrom = map["idFrom"];
    idTo = map["idTo"];
  }

  Map<String, dynamic> toMap() {
    return {
      "chatroomid": chatroomid,
      "participants": participants,
      "lastmessage": lastMessage,
      "read": read,
      "time":timeStamp,
      "count":count,
      "idFrom":idFrom,
      "idTo":idTo
    };
  }
}