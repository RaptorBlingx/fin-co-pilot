import 'package:flutter/material.dart';
import '../../../models/couple_account.dart';
import '../../../services/auth_service.dart';
import '../../../services/couples_service.dart';
import '../../../services/ai_mediator_service.dart';

/// AI Mediator Screen (Week 11 Feature)
///
/// Shows detected financial conflicts and AI-generated mediation advice:
/// - Active conflicts (unresolved)
/// - Resolved conflicts history
/// - Detailed mediation advice
/// - One-tap resolution marking
class AIMediatorScreen extends StatefulWidget {
  const AIMediatorScreen({super.key});

  @override
  State<AIMediatorScreen> createState() => _AIMediatorScreenState();
}

class _AIMediatorScreenState extends State<AIMediatorScreen> {
  final CouplesService _couplesService = CouplesService();
  final AIMediatorService _mediatorService = AIMediatorService();
  final AuthService _authService = AuthService();

  CoupleAccount? _coupleAccount;
  List<CoupleConflict> _activeConflicts = [];
  List<CoupleConflict> _resolvedConflicts = [];
  bool _isLoading = true;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final account = await _couplesService.getActiveCoupleAccount(user.uid);

      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No couple account found. Please pair with your partner first.'),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _coupleAccount = account;
        _activeConflicts = account.activeConflicts;
        _resolvedConflicts = account.resolvedConflicts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _detectNewConflicts() async {
    if (_coupleAccount == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final partnerId = _coupleAccount!.getPartnerId(user.uid);
    if (partnerId == null) return;

    setState(() => _isDetecting = true);

    try {
      final conflict = await _mediatorService.detectConflict(
        coupleAccountId: _coupleAccount!.id,
        user1Id: user.uid,
        user2Id: partnerId,
        sinceDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      if (conflict != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New conflict detected!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _loadData(); // Refresh
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new conflicts detected. Great job!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting conflicts: $e')),
        );
      }
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _resolveConflict(String conflictId) async {
    if (_coupleAccount == null) return;

    try {
      await _mediatorService.resolveConflict(
        coupleAccountId: _coupleAccount!.id,
        conflictId: conflictId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conflict marked as resolved!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData(); // Refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving conflict: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mediator'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isDetecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isDetecting ? null : _detectNewConflicts,
            tooltip: 'Detect New Conflicts',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(theme),
                    const SizedBox(height: 32),

                    // Active conflicts
                    if (_activeConflicts.isNotEmpty) ...[
                      _buildSectionTitle(theme, 'Active Conflicts', _activeConflicts.length),
                      const SizedBox(height: 16),
                      ..._activeConflicts.map((conflict) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildConflictCard(theme, conflict, isActive: true),
                          )),
                      const SizedBox(height: 32),
                    ],

                    // Resolved conflicts
                    if (_resolvedConflicts.isNotEmpty) ...[
                      _buildSectionTitle(theme, 'Resolved Conflicts', _resolvedConflicts.length),
                      const SizedBox(height: 16),
                      ..._resolvedConflicts.map((conflict) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildConflictCard(theme, conflict, isActive: false),
                          )),
                    ],

                    // Empty state
                    if (_activeConflicts.isEmpty && _resolvedConflicts.isEmpty)
                      _buildEmptyState(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.purple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Mediator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your supportive financial advisor for couples',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictCard(ThemeData theme, CoupleConflict conflict, {required bool isActive}) {
    return Card(
      elevation: isActive ? 3 : 1,
      color: isActive ? null : Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.warning_amber : Icons.check_circle,
                  color: isActive ? Colors.orange : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.topic,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(conflict.detectedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mediation advice
          if (conflict.mediationSummary != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mediation Advice',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    conflict.mediationSummary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Actions
          if (isActive)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _resolveConflict(conflict.id),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resolved ${_formatDate(conflict.resolvedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  size: 64,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Conflicts Detected',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You and your partner are doing great with your finances! Keep up the good communication.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isDetecting ? null : _detectNewConflicts,
                icon: _isDetecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isDetecting ? 'Detecting...' : 'Run Detection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
