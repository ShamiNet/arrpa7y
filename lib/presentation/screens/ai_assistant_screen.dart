import 'package:arrpa7y/logic/user_provider.dart';
import 'package:arrpa7y/presentation/screens/saved_ai_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../logic/ai_provider.dart';
import '../../core/theme/app_colors.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'أعطني ملخصاً مالياً شاملاً لرؤوس الأموال والأرباح',
    'من هم أعلى 3 مستثمرين من حيث رأس المال؟',
    'كم عدد الحسابات المجمدة حالياً وما هو إجمالي أرصدتها؟',
    'اقترح عليّ خطة توزيع أرباح متوازنة لهذا الشهر',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AiProvider aiProvider) {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    // 👈 جلب المحافظ الحالية وتغذيتها للذكاء الاصطناعي
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _promptController.clear();
    aiProvider.sendPrompt(text, userProvider.wallets);
    _scrollToBottom();
  }

  /// 📲 دالة تنسيق النص خصيصاً للواتساب مع الرموز والتنسيقات
  String _formatForWhatsApp(String rawText) {
    String formatted = rawText;

    // 1. تحويل العناوين (### Title) إلى نص عريض ومزين
    formatted = formatted.replaceAllMapped(
      RegExp(r'^#{1,6}\s*(.+)$', multiLine: true),
      (match) => '📌 *${match.group(1)?.trim()}*\n▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️▫️',
    );

    // 2. تحويل التغليظ المزدوج **نص** إلى تغليظ الواتساب *نص*
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '*${match.group(1)}*',
    );

    // 3. تحويل النقاط العادية (- أو *) إلى إيموجي أنيق (🔹)
    formatted = formatted.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s+', multiLine: true),
      (match) => '🔹 ',
    );

    // 4. تحويل الفواصل (---) إلى خطوط بصرية جميلة
    formatted = formatted.replaceAllMapped(
      RegExp(r'^\s*---\s*$', multiLine: true),
      (match) => '────────────────────────',
    );

    // هيدر وفوتر أنيق مخصص لرسائل الواتساب
    final String dateStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
    ).format(DateTime.now());
    final String header =
        "📊 *تقرير إداري | نظام الشامي المالي*\n"
        "🗓️ *التاريخ:* $dateStr\n"
        "────────────────────────\n\n";

    final String footer =
        "\n\n────────────────────────\n"
        "📱 *تم التصدير آلياً بواسطة المساعد الذكي*";

    return "$header${formatted.trim()}$footer";
  }

  // دالة النسخ مع إشعارات وتهيئة الواتساب
  void _copyToClipboard(String text) {
    final formattedText = _formatForWhatsApp(text);
    Clipboard.setData(ClipboardData(text: formattedText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
            SizedBox(width: 8),
            Text('تم نسخ التقرير بتنسيق مميز ومناسب للواتساب 📲'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المساعد الذكي لإدارة الشامي'),
            Text(
              'تحليل حركي وإجابة عن كافة بيانات النظام',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // 📌 زر الانتقال لصفحة المحفوظات
          IconButton(
            tooltip: 'التقارير المحفوظة',
            icon: const Icon(Icons.bookmarks_rounded, color: AppColors.gold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedAiReportsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'تصفية المحادثة',
            icon: const Icon(Icons.cleaning_services_rounded),
            onPressed: () => aiProvider.clearChat(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: aiProvider.messages.isEmpty
                ? _buildEmptyState(theme, aiProvider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: aiProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = aiProvider.messages[index];
                      return _buildMessageBubble(msg, theme, aiProvider);
                    },
                  ),
          ),

          if (aiProvider.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '🤖 الذكاء الاصطناعي يحلل بيانات النظام ويجهز الرد...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          _buildInputArea(theme, aiProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AiProvider aiProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 54,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'أهلاً بك في المحرك التحليلي الذكي',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك مطالبتي بإجراء حسابات، تقديم كشوفات، أو تحليل بيانات جميع المستثمرين والمافظ.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'أسئلة مقترحة:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) {
              return ActionChip(
                avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                label: Text(prompt, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  _promptController.text = prompt;
                  _handleSend(aiProvider);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    AiChatMessage msg,
    ThemeData theme,
    AiProvider aiProvider,
  ) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white24
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                    size: 14,
                    color: isUser ? Colors.white : AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isUser ? 'أنت (المدير)' : 'المساعد الذكي',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),

                if (!isUser) ...[
                  // 📌 زر حفظ التقرير
                  InkWell(
                    onTap: () async {
                      final int currentIndex = aiProvider.messages.indexOf(msg);
                      String promptText = 'تقرير تحليلي';
                      if (currentIndex > 0 &&
                          aiProvider.messages[currentIndex - 1].isUser) {
                        promptText = aiProvider.messages[currentIndex - 1].text;
                      }

                      final success = await aiProvider.saveAiReport(
                        prompt: promptText,
                        replyText: msg.text,
                      );

                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 تم حفظ التقرير بنجاح في الأرشيف!',
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_add_rounded,
                            size: 13,
                            color: AppColors.gold,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'حفظ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 📋 زر النسخ للواتساب
                  InkWell(
                    onTap: () => _copyToClipboard(msg.text),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'نسخ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: TextStyle(
                    fontSize: 9,
                    color: isUser ? Colors.white60 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (isUser)
              SelectableText(
                msg.text,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.5,
                ),
              )
            else
              MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: theme.colorScheme.onSurface,
                  ),
                  h3: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    height: 1.8,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  listBullet: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, AiProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(aiProvider),
                decoration: const InputDecoration(
                  hintText: 'اسأل الذكاء الاصطناعي أي شيء عن التطبيق...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: aiProvider.isLoading
                  ? null
                  : () => _handleSend(aiProvider),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
