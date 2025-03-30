class Message {
  final String content;
  final bool isUser;

  Message({
    required this.content,
    required this.isUser,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      isUser: json['isUser'],
    );
  }
}
