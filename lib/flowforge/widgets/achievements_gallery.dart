import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/achievement.dart';
import '../state/gamification_state.dart';
import '../services/achievement_service.dart';

/// Achievements gallery showing all unlockable achievements
class AchievementsGallery extends StatelessWidget {
  const AchievementsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationState>(
      builder: (context, gamification, child) {
        final unlockedIds = gamification.profile.unlockedAchievements;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: Achievements.all.length,
          itemBuilder: (context, index) {
            final achievement = Achievements.all[index];
            final isUnlocked = unlockedIds.contains(achievement.id);

            return AchievementCard(
              achievement: achievement,
              isUnlocked: isUnlocked,
            );
          },
        );
      },
    );
  }
}

/// Individual achievement card
class AchievementCard extends StatefulWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
  });

  final Achievement achievement;
  final bool isUnlocked;

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isUnlocked) {
      // Play shimmer animation on unlock
      _shimmerController.repeat();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _shimmerController.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = !widget.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isUnlocked
              ? widget.achievement.rarity.color.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: widget.isUnlocked
            ? [
                BoxShadow(
                  color: widget.achievement.rarity.color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAchievementDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isUnlocked
                        ? RadialGradient(
                            colors: [
                              widget.achievement.rarity.color.withOpacity(0.3),
                              widget.achievement.rarity.color.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: isLocked
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                  ),
                  child: Icon(
                    widget.achievement.icon,
                    size: 36,
                    color: isLocked
                        ? theme.colorScheme.outline
                        : widget.achievement.rarity.color,
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  widget.achievement.hiddenUntilUnlocked && isLocked
                      ? '???'
                      : widget.achievement.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? theme.colorScheme.outline
                        : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.achievement.rarity.color.withOpacity(
                      isLocked ? 0.1 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.achievement.rarity.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isLocked
                          ? theme.colorScheme.outline
                          : widget.achievement.rarity.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (isLocked) ...[
                  const SizedBox(height: 8),
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = !widget.isUnlocked;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isUnlocked
                      ? RadialGradient(
                          colors: [
                            widget.achievement.rarity.color.withOpacity(0.3),
                            widget.achievement.rarity.color.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: isLocked
                      ? theme.colorScheme.surfaceContainerHighest
                      : null,
                ),
                child: Icon(
                  widget.achievement.icon,
                  size: 48,
                  color: isLocked
                      ? theme.colorScheme.outline
                      : widget.achievement.rarity.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.achievement.hiddenUntilUnlocked && isLocked
                    ? 'Hidden Achievement'
                    : widget.achievement.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.achievement.rarity.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.achievement.rarity.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.achievement.rarity.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.achievement.hiddenUntilUnlocked && isLocked
                    ? 'Complete the hidden requirement to unlock'
                    : widget.achievement.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
