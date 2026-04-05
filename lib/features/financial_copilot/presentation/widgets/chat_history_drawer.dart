import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../models/chat_session.dart';
import '../../../../services/chat_history_service.dart';

/// A left-side drawer that displays chat session history.
class ChatHistoryDrawer extends StatelessWidget {
  final String userId;
  final String? currentSessionId;
  final ChatHistoryService historyService;
  final int maxSessions;
  final ValueChanged<ChatSession> onSessionSelected;
  final VoidCallback onNewChat;

  const ChatHistoryDrawer({
    super.key,
    required this.userId,
    required this.currentSessionId,
    required this.historyService,
    required this.maxSessions,
    required this.onSessionSelected,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.isDark
          ? AppTheme.darkSurface
          : AppTheme.slate50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(DesignTokens.radiusXL),
          bottomRight: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(child: _buildSessionList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space20,
        DesignTokens.space16,
        DesignTokens.space12,
        DesignTokens.space12,
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.chatCircleDots(),
            size: DesignTokens.iconMD,
            color: AppTheme.primaryIndigo,
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              'Chat History',
              style: context.textTheme.titleMedium,
            ),
          ),
          Material(
            color: AppTheme.primaryIndigo.withOpacity(0.1),
            borderRadius: DesignTokens.borderRadiusSM,
            child: InkWell(
              borderRadius: DesignTokens.borderRadiusSM,
              onTap: () {
                HapticUtils.light();
                Navigator.pop(context);
                onNewChat();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plus(),
                      size: DesignTokens.iconSM,
                      color: AppTheme.primaryIndigo,
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    Text(
                      'New',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    return StreamBuilder<List<ChatSession>>(
      stream: historyService.getSessions(userId, limit: maxSessions),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.space32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.space8,
          ),
          itemCount: sessions.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: DesignTokens.space2),
          itemBuilder: (context, index) =>
              _buildSessionTile(context, sessions[index])
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 200),
                    delay: Duration(milliseconds: 40 * index),
                  )
                  .slideX(begin: -0.1, end: 0),
        );
      },
    );
  }

  Widget _buildSessionTile(BuildContext context, ChatSession session) {
    final isActive = session.id == currentSessionId;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.space20),
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.rose500,
          borderRadius: DesignTokens.borderRadiusMD,
        ),
        child: Icon(PhosphorIcons.trash(), color: Colors.white, size: DesignTokens.iconSM),
      ),
      confirmDismiss: (_) async {
        HapticUtils.light();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text('This conversation will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.rose500,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        historyService.deleteSession(userId, session.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8),
        child: Material(
          color: isActive
              ? AppTheme.primaryIndigo.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: DesignTokens.borderRadiusMD,
          child: InkWell(
            borderRadius: DesignTokens.borderRadiusMD,
            onTap: () {
              HapticUtils.light();
              Navigator.pop(context);
              onSessionSelected(session);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.chatCircle(),
                    size: DesignTokens.iconSM,
                    color: isActive
                        ? AppTheme.primaryIndigo
                        : context.colors.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppTheme.primaryIndigo
                                : context.colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRelativeDate(session.updatedAt),
                          style: context.textTheme.labelSmall?.copyWith(
                            color:
                                context.colors.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.messageCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space6,
                        vertical: DesignTokens.space2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.onSurface.withOpacity(0.06),
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                      child: Text(
                        '${session.messageCount}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.chatCircleDots(),
              size: 48,
              color: context.colors.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'No conversations yet',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Start a new chat to get going',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == date.day) return 'Today';
    if (diff.inHours < 48) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
