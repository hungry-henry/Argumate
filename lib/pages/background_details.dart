import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

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
  final _backgroundController = TextEditingController();
  final _dio = Dio();
  File? _imageFile;
  bool _isLoading = false;
  String _selectedScene = '手动输入';
  final List<String> _scenes = ['争吵', '辩论', '商业饭局', '说服某人', '解释某事', '手动输入'];

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
      });
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
目标：${_goalController.text.isEmpty ? '请你根据场景，分析出用户想要达到的目标' : _goalController.text}
背景：${_backgroundController.text}
''';

      final response = await _dio.post(
        'https://api.siliconflow.cn/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization':
                'Bearer sk-jrcutvtjanedrbdgqhxxmchwzouzjcqddfjidrvwpecakvec',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
          "messages": [
            {
              "role": "system",
              "content": "你是一个专业的沟通专家，擅长根据不同的场景和需求，提供针对性的沟通建议。"
            },
            {"role": "user", "content": prompt}
          ],
          "stream": false,
          "max_tokens": 512,
          "temperature": 0.7,
          "top_p": 0.7,
          "top_k": 50,
          "frequency_penalty": 0.5,
          "n": 1,
          "response_format": {"type": "text"},
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
              const SizedBox(height: 16),
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
                      } else {
                        _sceneController.text = '';
                      }
                    });
                  }
                },
              ),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: '期望目标',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('选择聊天图片'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 8),
                Text('已选择图片: ${_imageFile!.path.split('/').last}'),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _backgroundController,
                decoration: const InputDecoration(
                  labelText: '背景叙述 *',
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
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
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
