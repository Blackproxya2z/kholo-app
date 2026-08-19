import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/bloom_models.dart';
import '../../core/providers/bloom_providers.dart';
import '../../core/services/bloom_ai_guide_service.dart';

/// ─── KHOLO AI HEALTH GUIDE CONVERSATIONAL ASSISTANT ──────────────────────────
class BloomAiAssistantScreen extends ConsumerStatefulWidget {
  const BloomAiAssistantScreen({super.key});

  @override
  ConsumerState<BloomAiAssistantScreen> createState() =>
      _BloomAiAssistantScreenState();
}

class _BloomAiAssistantScreenState
    extends ConsumerState<BloomAiAssistantScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendUserMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _msgCtrl.clear();
    ref.read(bloomAiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(bloomLanguageProvider);
    final messages = ref.watch(bloomAiChatProvider);
    final isTyping = ref.watch(bloomAiChatProvider.notifier).isTyping;

    final isBn = lang == BloomLanguage.bn;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        backgroundColor: context.kCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: context.kInk,
          onPressed: () {
            HapticFeedback.selectionClick();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/bloom');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5E83), Color(0xFF533B58)],
                ),
              ),
              child: const Text('✨', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KHOLO AI Health Guide',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBn ? 'সক্রিয় স্বাস্থ্য পরামর্শক' : 'Clinical Knowledge Active',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.kInkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Reset / Clear chat
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: context.kInkMuted,
            tooltip: isBn ? 'নতুন চ্যাট' : 'New Chat',
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(bloomAiChatProvider.notifier).reset();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return _TypingIndicatorBubble(isDark: isDark);
                }

                final msg = messages[index];
                return _ChatMessageTile(
                  message: msg,
                  lang: lang,
                  isDark: isDark,
                );
              },
            ),
          ),

          // Suggested quick questions carousel
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BloomAiGuideService.quickPrompts.length,
              itemBuilder: (context, index) {
                final prompt = BloomAiGuideService.quickPrompts[index];
                final text = isBn ? prompt['bn']! : prompt['en']!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.kInk,
                      ),
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : KholoColors.blush.withValues(alpha: 0.6),
                    ),
                    onPressed: () => _sendUserMessage(text),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Field
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      style: GoogleFonts.inter(fontSize: 14, color: context.kInk),
                      onSubmitted: _sendUserMessage,
                      decoration: InputDecoration(
                        hintText: isBn
                            ? 'প্রশ্ন লিখুন (যেমন: Acne কেন হচ্ছে?)...'
                            : 'Ask a question (e.g. Why is my period late?)...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.kInkMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: KholoColors.wine,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => _sendUserMessage(_msgCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── CHAT MESSAGE TILE ────────────────────────────────────────────────────────
class _ChatMessageTile extends StatelessWidget {
  const _ChatMessageTile({
    required this.message,
    required this.lang,
    required this.isDark,
  });

  final BloomAiMessage message;
  final BloomLanguage lang;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isBn = lang == BloomLanguage.bn;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: KholoColors.wine,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // AI Response Bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 28),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242228) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : KholoColors.blush.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.title != null) ...[
              Text(
                message.title!,
                style: isBn
                    ? GoogleFonts.hindSiliguri(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KholoColors.wine,
                      )
                    : GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KholoColors.wine,
                      ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              message.text,
              style: isBn
                  ? GoogleFonts.hindSiliguri(
                      fontSize: 13.5,
                      color: context.kInk,
                      height: 1.45,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      color: context.kInk,
                      height: 1.4,
                    ),
            ),

            if (message.bulletPoints != null &&
                message.bulletPoints!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...message.bulletPoints!.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: KholoColors.terracotta),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: isBn
                              ? GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.kInk,
                                )
                              : GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.kInk,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (message.clinicalSource != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 13, color: KholoColors.sage),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Source: ${message.clinicalSource!}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.kInkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ─── TYPING INDICATOR ────────────────────────────────────────────────────────
class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242228) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'KHOLO AI is analyzing...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.kInkMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
