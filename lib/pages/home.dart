import 'dart:math';
import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'background_details.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  final dio = Dio();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  static const int maxContextTokens = 1000;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? conversationsJson = prefs.getString('conversations');
    if (conversationsJson != null) {
      final List<dynamic> decoded = json.decode(conversationsJson);
      setState(() {
        _conversations =
            decoded.map((item) => Conversation.fromJson(item)).toList();
      });
    }
    _createNewConversation();
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    // Filter out empty conversations before saving
    final nonEmptyConversations =
        _conversations.where((c) => c.messages.isNotEmpty).toList();
    final String encoded =
        json.encode(nonEmptyConversations.map((c) => c.toJson()).toList());
    await prefs.setString('conversations', encoded);
  }

  void _createNewConversation() {
    //删除空白对话
    _conversations.removeWhere((c) => c.messages.isEmpty);

    final newConversation = Conversation(
      id: const Uuid().v4(),
      title: '新对话 ${_conversations.length + 1}',
      messages: [],
      createdAt: DateTime.now(),
    );
    setState(() {
      _conversations.insert(0, newConversation);
      _currentConversation = newConversation;
    });
    _saveConversations();
  }

  Future<void> _renameConversation(Conversation conversation) async {
    final TextEditingController renameController =
        TextEditingController(text: conversation.title);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名对话'),
        content: TextField(
          autofocus: true,
          controller: renameController,
          decoration: const InputDecoration(
            hintText: '输入新的对话名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (renameController.text.isNotEmpty) {
                setState(() {
                  final index =
                      _conversations.indexWhere((c) => c.id == conversation.id);
                  if (index != -1) {
                    _conversations[index] = conversation.copyWith(
                      title: renameController.text,
                    );
                    if (_currentConversation?.id == conversation.id) {
                      _currentConversation = _conversations[index];
                    }
                  }
                });
                _saveConversations();
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _conversations.removeWhere((c) => c.id == conversation.id);
                if (_currentConversation?.id == conversation.id) {
                  _createNewConversation();
                }
              });
              _saveConversations();
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(String text) async {
    if (_currentConversation == null) return;

    setState(() {
      _isLoading = true;
      _currentConversation = _currentConversation!.copyWith(
        messages: [
          ..._currentConversation!.messages,
          Message(content: text, isUser: true)
        ],
      );
    });

    try {
      // Prepare context with token limit
      final context = _currentConversation!.messages
          .takeWhile((msg) => msg.content.length <= maxContextTokens)
          .map((msg) => {
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
              })
          .toList();

      context.add({
        "role": "system",
        "content": "你是一个专业的沟通专家，擅长根据不同的场景和需求，提供针对性的沟通建议。"
      });

      final response = await dio.post(
        'http://api.hungryhenry.xyz/v1/chat/completions',
        options: Options(
          headers: {
            "Authorization":
                "Bearer fa3e340c52371fb3b05c1ecbd1abdabdf53cd8d5@eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY3RpdmF0ZWQiOnRydWUsImFnZSI6MSwiYmFuZWQiOmZhbHNlLCJjcmVhdGVfYXQiOjE3NDM4NDU2NDksImV4cCI6MTc0Mzg0NzQ0OSwibW9kZSI6Miwib2FzaXNfaWQiOjIxOTc0OTQyMDMyODU0NjMwNCwidmVyc2lvbiI6Mn0.JENO4aEe_TizaHpVGn8WLntKrrD9CzUxyYv6Dsku6DI...eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjEwMjAwLCJkZXZpY2VfaWQiOiJmYTNlMzQwYzUyMzcxZmIzYjA1YzFlY2JkMWFiZGFiZGY1M2NkOGQ1IiwiZXhwIjoxNzQ2NDM3NjQ5LCJvYXNpc19pZCI6MjE5NzQ5NDIwMzI4NTQ2MzA0LCJvYXNpc19yX2F0IjoxNzQzODQ1NjMyLCJwbGF0Zm9ybSI6IndlYiIsInZlcnNpb24iOjN9.XhQNFoDYrVWk5cRlcXHE4Zi7A0BPN5gNX8g9BVIC-64"
          },
        ),
        data: {
          "model": "step",
          "messages": context,
        },
      );

      if (response.statusCode == 400) {
        setState(() {
          _currentConversation = _currentConversation!.copyWith(
            messages: [
              ..._currentConversation!.messages,
              Message(content: response.data['message'], isUser: false),
            ],
          );
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _currentConversation = _currentConversation!.copyWith(
            messages: [
              ..._currentConversation!.messages,
              Message(content: "API密钥错误。", isUser: false),
            ],
          );
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _currentConversation = _currentConversation!.copyWith(
            messages: [
              ..._currentConversation!.messages,
              Message(content: "请求过于频繁，请稍后再试。", isUser: false),
            ],
          );
        });
      } else if (response.statusCode == 200) {
        setState(() {
          _currentConversation = _currentConversation!.copyWith(
            messages: [
              ..._currentConversation!.messages,
              Message(
                content: response.data['choices'][0]['message']['content'],
                isUser: false,
              ),
            ],
          );
          // Update conversation in list
          final index = _conversations
              .indexWhere((c) => c.id == _currentConversation!.id);
          if (index != -1) {
            _conversations[index] = _currentConversation!;
          }
        });
        _saveConversations();
      } else {
        setState(() {
          _currentConversation = _currentConversation!.copyWith(
            messages: [
              ..._currentConversation!.messages,
              Message(content: "请求失败，请稍后再试", isUser: false),
            ],
          );
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _currentConversation = _currentConversation!.copyWith(
          messages: [
            ..._currentConversation!.messages,
            Message(
              content: '请求失败，请稍后再试或反馈给hungryhenry101@outlook.com',
              isUser: false,
            ),
          ],
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _switchConversation(Conversation conversation) {
    setState(() {
      _currentConversation = conversation;
    });
    Navigator.pop(context); // Close drawer
  }

  void _showOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('重命名'),
            onTap: () {
              Navigator.pop(context);
              _renameConversation(conversation);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSceneButton(BuildContext context, String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BackgroundDetailsPage(scene: text),
          ),
        ).then((result) {
          if (result != null) {
            setState(() {
              _currentConversation = _currentConversation!.copyWith(
                messages: [
                  ..._currentConversation!.messages,
                  Message(content: result['response'], isUser: false),
                ],
              );
            });
            _saveConversations();
          }
        });
      },
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFE1E0DB)
            : const Color(0xFF0A1631),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (images.length > 8) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最多只能选择8张图片')),
            );
          }
          return;
        }
        setState(() {
          _selectedImages = images;
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BackgroundDetailsPage(
                images: _selectedImages,
              ),
            ),
          ).then((result) {
            if (result != null) {
              setState(() {
                _currentConversation = _currentConversation!.copyWith(
                  messages: [
                    ..._currentConversation!.messages,
                    Message(content: result['response'], isUser: false),
                  ],
                );
              });
              _saveConversations();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择图片失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: Text(_currentConversation?.title ?? S.current.argumate),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackgroundDetailsPage(),
                ),
              ).then((result) {
                if (result != null) {
                  setState(() {
                    _currentConversation = _currentConversation!.copyWith(
                      messages: [
                        ..._currentConversation!.messages,
                        Message(content: result['response'], isUser: false),
                      ],
                    );
                  });
                  _saveConversations();
                }
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      S.current.argumate,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新建对话'),
              onTap: () {
                _createNewConversation();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: max(
                    _conversations.where((c) => c.messages.isNotEmpty).length,
                    1),
                itemBuilder: (context, index) {
                  if (_conversations
                      .where((c) => c.messages.isNotEmpty)
                      .isEmpty) {
                    return const Center(child: Text('没有对话'));
                  } else {
                    final conversation = _conversations
                        .where((c) => c.messages.isNotEmpty)
                        .toList()[index];
                    final isSelected =
                        conversation.id == _currentConversation?.id;
                    return GestureDetector(
                      onLongPress: () => _showOptions(conversation),
                      onSecondaryTap: () => _showOptions(conversation),
                      child: ListTile(
                        leading: const Icon(Icons.chat),
                        title: Text(conversation.title),
                        subtitle: Text(
                          '${conversation.messages.length ~/ 2} 条消息',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        selected: isSelected,
                        onTap: () => _switchConversation(conversation),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: _currentConversation == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Expanded(
                    child: _currentConversation!.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0),
                                  child: Text(
                                    '帮助您更有效地沟通、劝说、辩论...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildSceneButton(
                                        context, '争吵', Icons.warning),
                                    _buildSceneButton(
                                        context, '辩论', Icons.people),
                                    _buildSceneButton(
                                        context, '商业饭局', Icons.business),
                                    _buildSceneButton(
                                        context, '说服某人', Icons.person),
                                    _buildSceneButton(
                                        context, '解释某事', Icons.info),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _currentConversation!.messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  _currentConversation!.messages[index];
                              return Align(
                                alignment: message.isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.isUser
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    message.content,
                                    style: TextStyle(
                                      color: message.isUser
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30.0, right: 16.0),
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: _pickImages,
                        child: const Icon(Icons.add_photo_alternate),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: false,
                            controller: controller,
                            style: Theme.of(context).textTheme.bodyLarge,
                            minLines: 1,
                            maxLines: 3,
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _sendRequest(value);
                                controller.clear();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: S.current.inputHint,
                              hintStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              _sendRequest(controller.text);
                              controller.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFFE1E0DB)
                                    : const Color(0xFF0A1631),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
