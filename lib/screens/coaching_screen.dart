import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/coaching_tip.dart';
import '../services/proactive_coach_agent.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen>
    with TickerProviderStateMixin {
  final ProactiveCoachAgent _coachAgent = ProactiveCoachAgent();
  final ScrollController _scrollController = ScrollController();
  bool _isGeneratingTips = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateNewTips() async {
    if (_isGeneratingTips) return;

    setState(() {
      _isGeneratingTips = true;
    });

    try {
      await _coachAgent.generateWeeklyCoaching(userId: 'current-user-id');
      _showSuccessSnackBar('New coaching tips generated! 🎯');
    } catch (e) {
      _showErrorSnackBar('Failed to generate tips: ${e.toString()}');
    } finally {
      setState(() {
        _isGeneratingTips = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Your Financial Coach',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsightsDialog(),
            tooltip: 'Coaching Insights',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coaching_tips')
            .where('userId', isEqualTo: 'current-user-id')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tips = snapshot.data!.docs
              .map((doc) => CoachingTip.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (tips.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _generateNewTips,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.builder(
                    itemCount: tips.length,
                    itemBuilder: (context, index) {
                      final tip = tips[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCoachingTipCard(tip, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _isGeneratingTips ? null : _generateNewTips,
          icon: _isGeneratingTips
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_isGeneratingTips ? 'Generating...' : 'Get New Tips'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCoachingTipCard(CoachingTip tip, int index) {
    final isNew = tip.isNew;
    
    return Hero(
      tag: 'tip_${tip.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: isNew
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type icon and priority
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tip.priorityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tip.priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tip.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tip.priorityColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (isNew) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${tip.priority.toUpperCase()} PRIORITY',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tip.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    
                    // Action button if available
                    if (tip.hasAction) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleTipAction(tip),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(tip.actionText ?? 'Take Action'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Footer with engagement actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _dismissTip(tip),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Dismiss'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _markAsHelpful(tip),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Helpful'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready for Your First Coaching Session?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized financial insights and actionable tips based on your spending patterns.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generateNewTips,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Get My First Tips'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your coaching tips.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTipAction(CoachingTip tip) {
    // Handle specific actions based on tip type and content
    if (tip.actionText?.toLowerCase().contains('budget') == true) {
      // For now show action dialog - can implement navigation later
      _showActionDialog(tip);
    } else if (tip.actionText?.toLowerCase().contains('goal') == true) {
      // For now show action dialog - can implement navigation later
      _showActionDialog(tip);
    } else {
      // Generic action
      _showActionDialog(tip);
    }
  }

  void _showActionDialog(CoachingTip tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tip.title),
        content: Text('This will help you: ${tip.message}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsActioned(tip);
            },
            child: const Text('Done!'),
          ),
        ],
      ),
    );
  }

  void _showInsightsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coaching Insights'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• AI analyzes your spending patterns weekly'),
            SizedBox(height: 8),
            Text('• Tips are personalized to your habits'),
            SizedBox(height: 8),
            Text('• Higher priority tips appear first'),
            SizedBox(height: 8),
            Text('• Take action to improve your score'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissTip(CoachingTip tip) async {
    try {
      await FirebaseFirestore.instance
          .collection('coaching_tips')
          .doc(tip.id)
          .update({'dismissed': true});
      
      _showSuccessSnackBar('Tip dismissed');
    } catch (e) {
      _showErrorSnackBar('Failed to dismiss tip');
    }
  }

  Future<void> _markAsHelpful(CoachingTip tip) async {
    try {
      await FirebaseFirestore.instance
          .collection('coaching_tips')
          .doc(tip.id)
          .update({
            'isHelpful': true,
            'engagementTimestamp': FieldValue.serverTimestamp(),
          });
      
      _showSuccessSnackBar('Thanks for your feedback! 👍');
    } catch (e) {
      _showErrorSnackBar('Failed to save feedback');
    }
  }

  Future<void> _markAsActioned(CoachingTip tip) async {
    try {
      await FirebaseFirestore.instance
          .collection('coaching_tips')
          .doc(tip.id)
          .update({
            'actionTaken': true,
            'actionTimestamp': FieldValue.serverTimestamp(),
          });
      
      _showSuccessSnackBar('Great job taking action! 🎯');
    } catch (e) {
      _showErrorSnackBar('Failed to save progress');
    }
  }
}