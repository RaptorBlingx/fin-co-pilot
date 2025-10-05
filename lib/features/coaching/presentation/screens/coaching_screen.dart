import 'package:flutter/material.dart';
import '../../../../services/proactive_coach_agent.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/models/coaching_tip.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/loading_button.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  final ProactiveCoachAgent _coach = ProactiveCoachAgent();
  final AuthService _authService = AuthService();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticUtils.light();
              _generateCoaching(user.uid);
            },
            tooltip: 'Generate new tips',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with generate button
          _buildHeader(user.uid),

          // Coaching tips stream
          Expanded(
            child: StreamBuilder<List<CoachingTip>>(
              stream: _coach.getAllTips(user.uid),
              builder: (context, snapshot) {
                // Add debugging
                print('🐛 StreamBuilder state: ${snapshot.connectionState}');
                print('🐛 Has data: ${snapshot.hasData}');
                print('🐛 Data length: ${snapshot.data?.length ?? 0}');
                print('🐛 Error: ${snapshot.error}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CardSkeleton(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tips = snapshot.data ?? [];
                print('🐛 Tips received: ${tips.map((t) => '${t.title} - read:${t.read} - dismissed:${t.dismissed}').toList()}');

                if (tips.isEmpty && !_isGenerating) {
                  return _buildEmptyState(user.uid);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tips.length,
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    return _buildTipCard(tip);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade100,
            Colors.blue.shade100,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Personal Finance Coach',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Personalized tips to build better habits',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (!_isGenerating) ...[
            ElevatedButton.icon(
              onPressed: () => _createTestTips(userId),
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _generateCoaching(userId),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('New Tips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No coaching tips yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate personalized financial coaching based on your spending habits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _generateCoaching(userId),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Coaching Tips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(CoachingTip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: tip.isNew ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tip.isNew ? Colors.purple.shade200 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _markAsRead(tip),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getGradient(tip.type),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.typeIcon,
                      style: const TextStyle(fontSize: 32),
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
                                  tip.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (tip.isNew)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dismiss button
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _dismissTip(tip),
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message
                Text(
                  tip.message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                // Action button (if actionable)
                if (tip.hasAction) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle action - for now just show snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tip.actionText!),
                            action: SnackBarAction(
                              label: 'Got it',
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(tip.actionText!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                // Priority badge
                const SizedBox(height: 12),
                _buildPriorityBadge(tip.priority),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${priority.toUpperCase()} PRIORITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient(String type) {
    switch (type.toLowerCase()) {
      case 'encouragement':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.teal.shade50],
        );
      case 'warning':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade50, Colors.deepOrange.shade50],
        );
      case 'milestone':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade50, Colors.yellow.shade50],
        );
      case 'challenge':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        );
    }
  }

  Future<void> _generateCoaching(String userId) async {
    setState(() => _isGenerating = true);
    
    try {
      print('🐛 Starting coaching generation for user: $userId');
      await _coach.generateWeeklyCoaching(userId: userId);
      print('🐛 Coaching generation completed');
      
      // Add a small delay and check for tips
      await Future.delayed(const Duration(seconds: 1));
      final tips = await _coach.getAllTips(userId).first;
      print('🐛 Tips after generation: ${tips.length} tips found');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New coaching tips generated! Found ${tips.length} tips'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🐛 Error generating coaching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating tips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _createTestTips(String userId) async {
    setState(() => _isGenerating = true);
    
    try {
      print('🐛 Creating test tips for user: $userId');
      await _coach.createTestTips(userId);
      print('🐛 Test tips creation completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test tips created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🐛 Error creating test tips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test tips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _markAsRead(CoachingTip tip) async {
    if (tip.isNew) {
      await _coach.markAsRead(tip.id);
    }
  }

  Future<void> _dismissTip(CoachingTip tip) async {
    await _coach.dismissTip(tip.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip dismissed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}