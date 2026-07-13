import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/typescript.dart'; // لتلوين كود السيرفر بدقة
import 'package:flutter_highlight/themes/monokai-sublime.dart'; // ستايل محرر الأكواد الداكن الاحترافي
import '../../logic/server_file_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

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
      if (!mounted) return;
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
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة السيرفر'),
            Text(
              'مستعرض آمن لملفات النظام',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        child: fileProvider.isLoading
          ? const AppStateView(kind: AppStateKind.loading)
          : fileProvider.errorMessage != null
          ? AppStateView(
              kind: AppStateKind.error,
              message: fileProvider.errorMessage,
              onRetry: fileProvider.fetchServerFiles,
            )
          : fileProvider.fileTree.isEmpty
          ? const AppStateView(
              kind: AppStateKind.empty,
              title: 'لا توجد ملفات متاحة',
              message: 'لم يُرجع السيرفر أي ملفات قابلة للإدارة.',
            )
          : RefreshIndicator(
              onRefresh: fileProvider.fetchServerFiles,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppSectionHeader(
                        title: 'شجرة ملفات المشروع',
                        subtitle:
                            '${fileProvider.fileTree.length} عنصراً في المستوى الرئيسي',
                        icon: Icons.account_tree_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: fileProvider.fileTree
                          .map<Widget>(_buildFileNode)
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
        leading: const Icon(Icons.folder_open_rounded, color: AppColors.gold),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: (node['children'] as List? ?? [])
            .map((child) => _buildFileNode(child))
            .toList(),
      );
    } else {
      return ListTile(
        leading: Icon(
          Icons.insert_drive_file_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(name),
        trailing: const Icon(Icons.edit_note_rounded),
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
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final String? codeContent = await provider.readFileContent(relativePath);
    if (!mounted) return;
    Navigator.pop(context); // إغلاق مؤشر التحميل

    if (codeContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر قراءة محتوى الملف من السيرفر.'),
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(
            0xFF23241F,
          ), // المظهر الداكن المريح للعين
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  relativePath,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
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
                          'تم حفظ الملف وتحديثه على السيرفر بنجاح.',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تعذر كتابة الملف وحفظه على السيرفر.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Directionality(
              textDirection: TextDirection.ltr,
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
      ),
    );
    codeController.dispose();
  }
}
