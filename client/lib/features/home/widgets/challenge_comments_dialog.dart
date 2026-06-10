import 'package:client/core/models/auth_session.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef ChallengeCommentSubmitter =
    Future<SavedBuilderProject?> Function(String message);
typedef ChallengeCommentDeleteHandler =
    Future<SavedBuilderProject?> Function(BuilderProjectComment comment);

class ChallengeCommentsDialog extends StatefulWidget {
  const ChallengeCommentsDialog({
    super.key,
    required this.project,
    required this.currentUser,
    required this.onSubmitComment,
    this.onDeleteComment,
  });

  final SavedBuilderProject project;
  final AuthUser currentUser;
  final ChallengeCommentSubmitter onSubmitComment;
  final ChallengeCommentDeleteHandler? onDeleteComment;

  @override
  State<ChallengeCommentsDialog> createState() =>
      _ChallengeCommentsDialogState();
}

class _ChallengeCommentsDialogState extends State<ChallengeCommentsDialog> {
  late SavedBuilderProject _project;
  late final TextEditingController _commentController;
  bool _isSubmitting = false;
  final Set<String> _deletingCommentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final updatedProject = await widget.onSubmitComment(message);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      if (updatedProject != null) {
        _project = updatedProject;
        _commentController.clear();
      }
    });
  }

  Future<void> _deleteComment(BuilderProjectComment comment) async {
    if (comment.id.isEmpty ||
        _deletingCommentIds.contains(comment.id) ||
        widget.onDeleteComment == null) {
      return;
    }

    setState(() {
      _deletingCommentIds.add(comment.id);
    });

    final updatedProject = await widget.onDeleteComment!(comment);
    if (!mounted) {
      return;
    }

    setState(() {
      _deletingCommentIds.remove(comment.id);
      if (updatedProject != null) {
        _project = updatedProject;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = _project.comments;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Challenge Discussion',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF243A1B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _project.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF667064),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_project),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  _SummaryPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${_project.commentCount} comments',
                    color: const Color(0xFF4A90E2),
                  ),
                  const SizedBox(width: 10),
                  _SummaryPill(
                    icon: Icons.star_rounded,
                    label:
                        '${_project.ratingAverage.toStringAsFixed(1)} (${_project.ratingCount})',
                    color: const Color(0xFFFFB300),
                  ),
                  const SizedBox(width: 10),
                  _SummaryPill(
                    icon: Icons.play_arrow_rounded,
                    label: '${_project.playCount} plays',
                    color: const Color(0xFF66B64A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          'No comments yet. Start the conversation with a helpful tip or a quick reaction.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF667064),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isCurrentUser =
                            comment.userId == widget.currentUser.id;
                        final canDeleteComment =
                            widget.onDeleteComment != null &&
                            comment.id.isNotEmpty;
                        final isDeleting = _deletingCommentIds.contains(
                          comment.id,
                        );
                        final timestamp = _formatTimestamp(
                          context,
                          comment.createdAt,
                        );

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE7E5D4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isCurrentUser
                                    ? const Color(0xFF66B64A)
                                    : const Color(0xFF9DB7D5),
                                child: Text(
                                  _initialsFor(comment.userName),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isCurrentUser
                                                ? '${comment.userName} (You)'
                                                : comment.userName,
                                            style: GoogleFonts.nunito(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF243A1B),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timestamp,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        if (canDeleteComment) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Delete comment',
                                            visualDensity:
                                                VisualDensity.compact,
                                            constraints: const BoxConstraints(
                                              minWidth: 30,
                                              minHeight: 30,
                                            ),
                                            padding: EdgeInsets.zero,
                                            onPressed: isDeleting
                                                ? null
                                                : () => _deleteComment(comment),
                                            icon: isDeleting
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                    color: Color(0xFFE53935),
                                                  ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment.message,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF475569),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E8),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Share feedback, ideas, or encouragement...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7E5D4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7E5D4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF66B64A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitComment,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF66B64A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 54),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Posting' : 'Post',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (words.isEmpty) {
      return 'U';
    }

    return words.map((part) => part[0].toUpperCase()).join();
  }

  String _formatTimestamp(BuildContext context, DateTime? value) {
    if (value == null) {
      return 'Just now';
    }

    final localValue = value.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatShortDate(localValue);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );
    return '$dateLabel • $timeLabel';
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
