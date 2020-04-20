import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _name = "Fei Fei";
const String _aiName = "Test";

// 聊天应用 demo
void main() => runApp(new FriendlyChatApp());

class FriendlyChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Firiendly Chat',
      home: new ChatScreen(),
    );
  }
}

// 聊天页面
class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _controller = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('FriendlyChat'),
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          new Divider(
            height: 1.0,
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _controller,
                onTap: _handleTaped,
                onChanged: _handleTextChanged,
                onSubmitted: _handleSubmitted,
                decoration:
                    InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            new Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: _isComposing
                    ? () => _handleSubmitted(_controller.text)
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  void _handleSubmitted(String text) async {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    // 发送消息
    var animationController = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 700));
    ChatMessage message = new ChatMessage(
      isSend: true,
      text: text,
      animationController: animationController,
    );
    setState(() {
      _messages.add(message);
    });

    // AI 回复消息
    var _url = "http://api.qingyunke.com/api.php?key=free&appid=0&msg=$text";
    var response = await http.get(_url);
    var jsonResponse = json.decode(response.body);
    ChatMessage aiMessage = new ChatMessage(
      isSend: false,
      text: jsonResponse['content'],
      animationController: animationController,
    );
    setState(() {
      _messages.add(aiMessage);
    });
    message.animationController.forward();
  }

  void _handleTaped() {
    // 滚动到最后
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }
}

// 聊天信息部件
class ChatMessage extends StatelessWidget {
  ChatMessage({this.isSend, this.text, this.animationController});

  bool isSend;
  String text;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return new FadeTransition(
      opacity: new CurvedAnimation(
          parent: animationController, curve: Curves.fastOutSlowIn),
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child:
            isSend ? _buildSendMessageLayout() : _buildReceivedMessageLayout(),
      ),
    );
  }

  Row _buildSendMessageLayout() {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        new Expanded(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              new Text(_name),
              new Container(
                  margin: const EdgeInsets.only(top: 5.0), child: _buildText()),
            ],
          ),
        ),
        new Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: new CircleAvatar(
              child: new Text(_name[0]),
            )),
      ],
    );
  }

  Row _buildReceivedMessageLayout() {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(
              child: new Text(_aiName[0]),
            )),
        new Expanded(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(_aiName),
              new Container(
                  margin: const EdgeInsets.only(top: 5.0), child: _buildText()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildText() {
    return !text.contains('{br}')
        ? new Text(text)
        : new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                text.split('{br}').map((subText) => new Text(subText)).toList(),
          );
  }
}
