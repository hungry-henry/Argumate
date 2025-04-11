import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

const List<String> scenePrompts = [
  '''你是一个帮助用户在吵架中获得优势、达到用户目标的沟通专家。请你依据以下要点，给出用户在吵架中应该如何回应。
1.要控制情绪，保持理智。及时觉察自己的情绪状态，并尝试调整到理智状态，避免被情绪牵着走 。
2.语言逻辑清晰，抓住重点，精准反击使用简洁、有力的语言，要直击要害。如果对方措辞不严谨，可以针对其漏洞提出质问，甚至重复追问，直到对方无法自圆其说。不要急于反驳，先听对方说完，找到破绽后再进行反击。
3.占据道德制高点：用道德优势压制对方。例如，如果对方使用侮辱性语言，你可以指出这种行为不礼貌，从而让对方陷入被动。
4. 攻守兼备：主动进攻是最好的防守。如果对方指责你，不要只是一味为自己辩解，而是主动反击，转移焦点。
5. 适时收尾。吵架的目的不是为了争输赢，而是为了解决问题。如果发现争吵已经没有意义，可以选择优雅地结束。''',
  '''你是一个帮助用户在辩论中获得优势、赢下辩论的沟通专家。请你依据以下要点，给出用户在辩论中应该如何回应。
1.辩论时，语言必须简洁明了，避免冗长或模糊的表述。任何论点都必须以最精准的语言表达出来，论点和语言技巧从来都是相辅相成。使用逻辑清晰的句式，例如“因为……所以……”、“如果……那么……”，让听众和评委能够迅速理解你的观点。
2.灵活运用反驳技巧：反问法：当对手提出强而有力的论点时，可以通过反问的方式夺回主导权，要求对方正面回应相关提问 。如果对手质疑你的论点，不要急于否定，而是针对质疑的地方进行详细解释，展现你对问题的深刻理解。适当认同对方的部分观点，但随后通过补充新的角度或信息，将其转化为对自己有利的内容。例如：“我同意您的看法，但还需要考虑的是……”
3.尝试用不同的同义词替换重复的表达，避免语言单调。
4.不要为了辩倒对方而生硬地反驳，而是找到对方逻辑中的漏洞，巧妙地引导讨论方向。
5.辩论不仅是技巧的比拼，也是个人素质的体现。注意仪态风度，语言文明，举止得体，避免情绪化或人身攻击 。即使面对激烈的交锋，也要保持冷静，展现出自信和从容的态度。
6.注意听清对方的发言论证是否严密，抓住其中的漏洞进行反击 。同时顾及本队的总观点，坚守住自己的分论点，并有机地组织材料，不失时机地给予对方有力的反驳。
7.适当的幽默可以让辩论更加生动有趣。慷慨激昂的语气和充满激情的表达方式，有助于增强你的观点的感染力。''',
  '''你是一个情感专家，要帮助用户（男性）拉近与女生的距离。请你依据以下要点，给出用户在聊天中应该如何回应。
1.找到共同兴趣点
2.适当保持距离，给彼此空间
3.要展现幽默，让气氛更加轻松
4.表达得体，不要过于直接或冒犯
5.不急于求成，慢慢建立关系
6.关注情感共鸣和情绪分享''',
  '''你是一个情感专家，要帮助用户（女性）拉近与男生的距离。请你依据以下要点，给出用户在聊天中应该如何回应。
1.找到共同兴趣点
2.适当保持距离，给彼此空间
3.要展现幽默，让气氛更加轻松
4.表达得体，不要过于直接或冒犯
5.不急于求成，慢慢建立关系
6.关注逻辑性和实际问题'''
];

class BackgroundDetailsPage extends StatefulWidget {
  final String? scene;
  final String? goal;

  const BackgroundDetailsPage({Key? key, this.scene, this.goal})
      : super(key: key);

  @override
  _BackgroundDetailsPageState createState() => _BackgroundDetailsPageState();
}

class _BackgroundDetailsPageState extends State<BackgroundDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _sceneController = TextEditingController();
  final _goalController = TextEditingController();
  final _analysisController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _dio = Dio();
  File? _imageFile;
  String? _imageName;
  bool _isLoading = false;
  bool _isUploading = false;
  String _uploadStatus = '';
  String? _imageText;
  String _selectedScene = '手动输入';
  String _sysPrompt = "你是一个专业的沟通专家，擅长根据不同的场景和需求，提供针对性的沟通建议。";
  final List<String> _scenes = [
    '争吵',
    '辩论',
    '与异性聊天（他）',
    '与异性聊天（她）',
    '商业饭局',
    '说服某人',
    '解释某事',
    '手动输入'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.scene != null) {
      _selectedScene = widget.scene!;
      _sceneController.text = widget.scene!;
    }
    if (widget.goal != null) {
      _goalController.text = widget.goal!;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _isUploading = true;
        _uploadStatus = '上传中...';
      });
      Response? uploadResponse;

      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_imageFile!.path),
        });

        uploadResponse = await _dio.post(
          'http://hungryhenry.xyz/api/image_upload.php',
          data: formData,
          options: Options(
            headers: {
              'User-Agent': 'argumate',
            },
          ),
        );

        if (uploadResponse.statusCode == 200) {
          setState(() {
            _uploadStatus = '解析图片中...';
            _imageName = jsonDecode(uploadResponse!.data)['filename'];
          });
          print(_imageName);
          Response? analysisResponse;

          try {
            analysisResponse = await _dio
                .post('http://api.hungryhenry.xyz/v1/chat/completions',
                    options: Options(
                      headers: {
                        "Authorization":
                            "Bearer fa3e340c52371fb3b05c1ecbd1abdabdf53cd8d5@eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY3RpdmF0ZWQiOnRydWUsImFnZSI6MSwiYmFuZWQiOmZhbHNlLCJjcmVhdGVfYXQiOjE3NDM4NDU2NDksImV4cCI6MTc0Mzg0NzQ0OSwibW9kZSI6Miwib2FzaXNfaWQiOjIxOTc0OTQyMDMyODU0NjMwNCwidmVyc2lvbiI6Mn0.JENO4aEe_TizaHpVGn8WLntKrrD9CzUxyYv6Dsku6DI...eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjEwMjAwLCJkZXZpY2VfaWQiOiJmYTNlMzQwYzUyMzcxZmIzYjA1YzFlY2JkMWFiZGFiZGY1M2NkOGQ1IiwiZXhwIjoxNzQ2NDM3NjQ5LCJvYXNpc19pZCI6MjE5NzQ5NDIwMzI4NTQ2MzA0LCJvYXNpc19yX2F0IjoxNzQzODQ1NjMyLCJwbGF0Zm9ybSI6IndlYiIsInZlcnNpb24iOjN9.XhQNFoDYrVWk5cRlcXHE4Zi7A0BPN5gNX8g9BVIC-64"
                      },
                    ),
                    data: {
                  "model": "step",
                  "messages": [
                    {
                      "role": "user",
                      "content": [
                        {
                          "type": "image_url",
                          "image_url": {
                            "url": "http://hungryhenry.xyz/uploads/$_imageName"
                          }
                        },
                        {
                          "type": "text",
                          "text":
                              "这是一个聊天软件中的截图。如果顶部有括号与数字，则这是一个群聊，括号中的数字代表群聊中的成员数量；如果顶部没有括号与数字，则这是私聊，且顶部的文字是私聊对象的昵称。右侧全部是我的发言，左侧是其他人的发言（如果是群聊，头像上方会有昵称。如果是私聊，截图顶部会显示对方的昵称）。请先按时间顺序（从上至下）告诉我原文，不要概括我们说了什么；然后告诉我你获得的信息（好友/群聊名称、聊天人数、聊天时间、语气态度等）"
                        }
                      ]
                    }
                  ],
                  "stream": false
                });

            if (analysisResponse.statusCode == 200) {
              setState(() {
                _uploadStatus = '解析成功';
                _isUploading = false;
                _imageText =
                    analysisResponse!.data['choices'][0]['message']['content'];
              });
              _analysisController.text = _imageText!;
            } else {
              throw Exception('Analysis failed');
            }
          } catch (e) {
            print(analysisResponse != null ? analysisResponse.data : e);
            setState(() {
              _uploadStatus = '解析失败';
              _isUploading = false;
              _imageFile = null;
              _imageName = null;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('图片解析失败，请重试')),
              );
            }
          }
        } else {
          throw Exception('Upload failed');
        }
      } catch (e) {
        print(uploadResponse != null ? uploadResponse.data : e);
        setState(() {
          _uploadStatus = '上传失败';
          _isUploading = false;
          _imageFile = null;
          _imageName = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片上传失败，请重试')),
          );
        }
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prompt = '''
场景：${_sceneController.text}
${_analysisController.text.isNotEmpty ? '消息：${_analysisController.text}' : ''}
目标：${_goalController.text.isEmpty ? '请你根据场景，分析出用户想要达到的目标' : _goalController.text}
背景：${_backgroundController.text}
输出：请你根据以上信息，告诉我接下来应该回应什么？给我几个选择即可，不要回复多余内容。
''';

      final response = await _dio.post(
        'http://api.hungryhenry.xyz/v1/chat/completions',
        options: Options(
          headers: {
            "Authorization":
                "Bearer fa3e340c52371fb3b05c1ecbd1abdabdf53cd8d5@eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY3RpdmF0ZWQiOnRydWUsImFnZSI6MSwiYmFuZWQiOmZhbHNlLCJjcmVhdGVfYXQiOjE3NDM4NDU2NDksImV4cCI6MTc0Mzg0NzQ0OSwibW9kZSI6Miwib2FzaXNfaWQiOjIxOTc0OTQyMDMyODU0NjMwNCwidmVyc2lvbiI6Mn0.JENO4aEe_TizaHpVGn8WLntKrrD9CzUxyYv6Dsku6DI...eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjEwMjAwLCJkZXZpY2VfaWQiOiJmYTNlMzQwYzUyMzcxZmIzYjA1YzFlY2JkMWFiZGFiZGY1M2NkOGQ1IiwiZXhwIjoxNzQ2NDM3NjQ5LCJvYXNpc19pZCI6MjE5NzQ5NDIwMzI4NTQ2MzA0LCJvYXNpc19yX2F0IjoxNzQzODQ1NjMyLCJwbGF0Zm9ybSI6IndlYiIsInZlcnNpb24iOjN9.XhQNFoDYrVWk5cRlcXHE4Zi7A0BPN5gNX8g9BVIC-64"
          },
        ),
        data: {
          "model": "step",
          "messages": [
            {"role": "system", "content": _sysPrompt},
            {"role": "user", "content": prompt}
          ]
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, {
            'prompt': prompt,
            'response': response.data['choices'][0]['message']['content']
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请求失败，请稍后重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发生错误，请稍后重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提供背景'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedScene == '手动输入') ...[
                TextFormField(
                  controller: _sceneController,
                  decoration: const InputDecoration(
                    labelText: '手动输入情景 *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择或输入情景';
                    }
                    return null;
                  },
                  readOnly: _selectedScene != '手动输入',
                )
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedScene,
                decoration: const InputDecoration(
                  labelText: '选择预设情景 *',
                  border: OutlineInputBorder(),
                ),
                items: _scenes.map((String scene) {
                  return DropdownMenuItem<String>(
                    value: scene,
                    child: Text(scene),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedScene = newValue;
                      if (newValue != '手动输入') {
                        _sceneController.text = newValue;
                        final index = _scenes.indexOf(newValue);
                        if (index <= scenePrompts.length) {
                          _sysPrompt = scenePrompts[index];
                        }
                      } else {
                        _sceneController.text = '';
                      }
                    });
                  }
                },
              ),
              const Divider(height: 30),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: '期望目标',
                  border: OutlineInputBorder(),
                ),
              ),
              const Divider(height: 30),
              if (!_isUploading && _uploadStatus != "解析成功") ...[
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('选择聊天图片'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
              if (_imageFile != null && _uploadStatus != "上传失败") ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_isUploading) ...[
                  const SizedBox(height: 8),
                  Text(_uploadStatus),
                ],
              ],
              const SizedBox(height: 16),
              if (_imageText != null) ...[
                TextFormField(
                  controller: _analysisController,
                  decoration: const InputDecoration(
                    labelText: '图片解析文字',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      _imageText = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _backgroundController,
                decoration: const InputDecoration(
                  labelText: '背景叙述 *',
                  hintText: '(原因是什么？什么时候发生的？在什么场合下？双方平时沟通风格如何？....)',
                  hintMaxLines: 5,
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                maxLength: 1000,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入背景叙述';
                  }
                  if (value.length > 1000) {
                    return '背景叙述不能超过1000字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ||
                        _uploadStatus == "上传中..." ||
                        _uploadStatus == "解析图片中..."
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _isLoading ||
                          _uploadStatus == "上传中..." ||
                          _uploadStatus == "解析图片中..."
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('提交'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sceneController.dispose();
    _goalController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
}
