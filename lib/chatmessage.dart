import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.sender,
    this.isImage = false,
  });

  final String text;
  final String sender;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final avatar = sender == "user"
        ? const Icon(
      Icons.account_circle,
      size: 40.0,
    )
        : const CircleAvatar(
      backgroundImage: AssetImage('assets/Icon.png'),
      radius: 20,
    );

    final messageBubble = Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: sender == "user" ? Colors.blueAccent : Colors.grey[400],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: sender == "user" ? Radius.circular(12) : Radius.circular(0),
          bottomRight: sender != "user" ? Radius.circular(12) : Radius.circular(0),
        ),
      ),
      child: text.trim().text.white.bodyText1(context).make().px8(),
    );

    final messageContent = isImage
        ? AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        text,
        loadingBuilder: (context, child, loadingProgress) =>
        loadingProgress == null
            ? child
            : const CircularProgressIndicator.adaptive(),
      ),
    )
        : messageBubble;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sender == "user"
          ? [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: messageContent,
          ),
        ),
        SizedBox(width: 8),
        avatar,
      ]
          : [
        avatar,
        SizedBox(width: 8),
        Expanded(child: messageContent),
      ],
    ).py8();
  }
}
