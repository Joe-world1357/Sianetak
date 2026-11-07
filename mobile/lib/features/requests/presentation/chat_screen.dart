import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/egypt_phone.dart';
import '../domain/request_models.dart';

/// Text chat bound to one request, between its customer and assigned technician.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.requestId,
    required this.reference,
    this.readOnly = false,
  });

  final String requestId;
  final String reference;
  final bool readOnly;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context);
    final requests = AppScope.of(context).requests;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await requests.sendMessage(widget.requestId, body);
      _text.clear();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chatTitle),
            Text(
              isolateLtr(widget.reference),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<List<ChatMessage>>(
              load: () => scope.requests.messages(widget.requestId),
              refreshOn: scope.changes,
              builder: (context, messages, _) => messages.isEmpty
                  ? EmptyView(
                      message: l10n.chatEmpty,
                      icon: Icons.forum_outlined,
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _Bubble(
                        message: messages[messages.length - 1 - i],
                        adminView: widget.readOnly,
                      ),
                    ),
            ),
          ),
          if (widget.readOnly)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SafeArea(
                top: false,
                child: Text(
                  l10n.chatReadOnly,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l10n.chatHint,
                            counterText: '',
                            isDense: true,
                            fillColor: AppColors.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filled(
                        tooltip: l10n.chatSend,
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.adminView});

  final ChatMessage message;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    // An admin reads both sides; put the technician on the "own" side for contrast.
    final mine = adminView ? message.senderRole == 'technician' : message.mine;
    final bg = mine ? AppColors.primary : Colors.white;
    final fg = mine ? Colors.white : AppColors.ink;
    const r = Radius.circular(18);
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: mine ? null : Border.all(color: AppColors.line),
            borderRadius: BorderRadiusDirectional.only(
              topStart: r,
              topEnd: r,
              bottomStart: mine ? const Radius.circular(4) : r,
              bottomEnd: mine ? r : const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (adminView)
                Text(
                  message.senderRole == 'technician'
                      ? l10n.roleTechnician
                      : l10n.roleCustomer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(message.text, style: TextStyle(color: fg, height: 1.4)),
              const SizedBox(height: 2),
              Text(
                formatTime(message.at, lang),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
