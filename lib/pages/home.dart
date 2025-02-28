import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.argumate),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      S.current.help,
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildOptionButton(S.current.wechat, Icons.wechat),
                      _buildOptionButton(S.current.voice, Icons.phone),
                      _buildOptionButton('总结文本', Icons.text_fields),
                      _buildOptionButton('代码', Icons.code),
                    ],
                  ),
                ],
              ),
            ),
            // 将 TextField 推到屏幕底部
            TextField(
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: S.current.inputHint,
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                suffixIcon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, IconData icon) {
    return TextButton.icon(
      onPressed: () {},
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Theme.of(context).scaffoldBackgroundColor == Colors.white ? Colors.black : Colors.white, width: 1),
        ),
      ),
      icon: Icon(icon, color: Theme.of(context).scaffoldBackgroundColor == Colors.white ? Colors.black : Colors.white),
      label: Text(
        text,
        style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor == Colors.white ? Colors.black : Colors.white),
      ),
    );
  }
}