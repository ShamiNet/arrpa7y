import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../logic/ai_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

class SavedAiReportsScreen extends StatelessWidget {
  const SavedAiReportsScreen({super.key});

  String _formatForWhatsApp(String rawText) {
    String formatted = rawText;
    formatted = formatted.replaceAllMapped(
      RegExp(r'^#{1,6}\s*(.+)$', multiLine: true),
      (match) => '📌 *${match.group(1)?.trim()}*\n▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️',
    );
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '*${match.group(1)}*',
    );
    formatted = formatted.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s+', multiLine: true),
      (match) => '🔹 ',
    );

    final String dateStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
    ).format(DateTime.now());
    return "📊 *تقرير محفوظ | نظام الشامي المالي*\n🗓️ *التاريخ:* $dateStr\n────────────────────────\n\n${formatted.trim()}\n\n────────────────────────\n📱 *تم التصدير من التقارير المحفوظة*";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = Provider.of<AiProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التقارير والإجابات المحفوظة'),
            Text(
              'أرشيف تحليلات الذكاء الاصطناعي',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('SavedAiReports')
              .orderBy('savedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppStateView(kind: AppStateKind.loading);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const AppStateView(
                kind: AppStateKind.empty,
                title: 'لا توجد تقارير محفوظة',
                message:
                    'انقر على زر "حفظ" في شاشة المساعد الذكي لحفظ التقرير هنا.',
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String prompt = data['prompt'] ?? 'بدون عنوان';
                final String reply = data['reply'] ?? '';
                final String savedAtStr = data['savedAt'] ?? '';

                DateTime savedDate = DateTime.now();
                if (savedAtStr.isNotEmpty) {
                  savedDate = DateTime.tryParse(savedAtStr) ?? DateTime.now();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. السؤال / عنوان التقرير
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                prompt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy/MM/dd • hh:mm a').format(savedDate),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(height: 20),

                        // 2. محتوى الإجابة
                        MarkdownBody(
                          data: reply,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: theme.colorScheme.onSurface,
                            ),
                            h3: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. أزرار التحكم (نسخ / مشاركة / حذف)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 📋 زر النسخ
                            TextButton.icon(
                              onPressed: () {
                                final formatted = _formatForWhatsApp(reply);
                                Clipboard.setData(
                                  ClipboardData(text: formatted),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تم نسخ النص بتنسيق الواتساب!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text(
                                'نسخ',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 📤 زر المشاركة
                            TextButton.icon(
                              onPressed: () {
                                final formatted = _formatForWhatsApp(reply);
                                Share.share(
                                  formatted,
                                  subject: 'تقرير الشامي المالي',
                                );
                              },
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text(
                                'مشاركة',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 🗑️ زر الحذف
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                              onPressed: () => _confirmDeleteReport(
                                context,
                                aiProvider,
                                doc.id,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'حذف',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteReport(
    BuildContext context,
    AiProvider provider,
    String docId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 32,
        ),
        title: const Text('حذف التقرير؟'),
        content: const Text(
          'هل أنت متأكد من حذف هذا التقرير من الأرشيف المحفوظ؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteSavedReport(docId);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
