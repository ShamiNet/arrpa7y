import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/typescript.dart'; // لتلوين كود السيرفر بدقة
import 'package:flutter_highlight/themes/monokai-sublime.dart'; // ستايل محرر الأكواد الداكن الاحترافي
import '../../logic/server_file_provider.dart';

class ServerManagerScreen extends StatefulWidget {
  const ServerManagerScreen({super.key});

  @override
  State<ServerManagerScreen> createState() => _ServerManagerScreenState();
}

class _ServerManagerScreenState extends State<ServerManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServerFileProvider>(
        context,
        listen: false,
      ).fetchServerFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<ServerFileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المستعرض والتحكم بملفات السيرفر',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: fileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fileProvider.errorMessage != null
          ? Center(child: Text('✗ خطأ: ${fileProvider.errorMessage}'))
          : RefreshIndicator(
              onRefresh: () => fileProvider.fetchServerFiles(),
              child: ListView.builder(
                itemCount: fileProvider.fileTree.length,
                itemBuilder: (context, index) {
                  return _buildFileNode(fileProvider.fileTree[index]);
                },
              ),
            ),
    );
  }

  // دالة بناء العقد الشجرية للمجلدات والملفات تفرعياً
  Widget _buildFileNode(dynamic node) {
    final bool isFolder = node['isFolder'] ?? false;
    final String name = node['name'] ?? '';
    final String relativePath = node['path'] ?? '';

    if (isFolder) {
      return ExpansionTile(
        leading: const Icon(Icons.folder_open, color: Colors.amber),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: (node['children'] as List? ?? [])
            .map((child) => _buildFileNode(child))
            .toList(),
      );
    } else {
      return ListTile(
        leading: const Icon(
          Icons.insert_drive_file_outlined,
          color: Colors.blueGrey,
        ),
        title: Text(name),
        trailing: const Icon(Icons.edit_note, color: Colors.grey),
        onTap: () => _openCodeEditor(relativePath, name),
      );
    }
  }

  // فتح نافذة المحرر البرمجي الذكي لتعديل الكود وحفظه
  void _openCodeEditor(String relativePath, String fileName) async {
    final provider = Provider.of<ServerFileProvider>(context, listen: false);

    // إظهار مؤشر تحميل أثناء قراءة كود الملف من السيرفر الحي
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final String? codeContent = await provider.readFileContent(relativePath);
    if (!mounted) return;
    Navigator.pop(context); // إغلاق مؤشر التحميل

    if (codeContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✗ تعذر قراءة محتوى الملف من السيرفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // تهيئة كائن محرر الكود البرمي مع ربطه بخصائص لغة TypeScript والمظهر الداكن
    final codeController = CodeController(
      text: codeContent,
      language: typescript,
    );

    // فتح شاشة المحرر الكاملة بصورة منبثقة ملء الشاشة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(
            0xFF23241F,
          ), // المظهر الداكن المريح للعين
          appBar: AppBar(
            title: Text(
              fileName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: const Color(0xFF1F1F1F),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.save_as_rounded,
                  color: Colors.greenAccent,
                ),
                onPressed: () async {
                  // إرسال كود التعديل الجديد وحفظه على سيرفرك فوراً
                  final success = await provider.saveFileContent(
                    relativePath,
                    codeController.text,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🚀 تم ترحيل الكود وحفظ وتحديث الملف على سيرفرك الحي بنجاح!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✗ خطأ أثناء محاولة كتابة وحفظ الملف'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: codeController,
                  textStyle: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
