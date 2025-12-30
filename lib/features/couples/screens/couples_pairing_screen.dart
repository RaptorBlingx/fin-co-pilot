import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/couple_account.dart';
import '../../../services/auth_service.dart';
import '../../../services/couples_service.dart';

/// Couples Pairing Screen (Week 11 Feature)
///
/// Enables users to:
/// - Send partner invitations via email
/// - View pending invitations
/// - Accept/decline partner invitations
/// - Generate shareable invitation links
class CouplesPairingScreen extends StatefulWidget {
  final String? invitationToken; // Optional: for deep link handling

  const CouplesPairingScreen({
    super.key,
    this.invitationToken,
  });

  @override
  State<CouplesPairingScreen> createState() => _CouplesPairingScreenState();
}

class _CouplesPairingScreenState extends State<CouplesPairingScreen> {
  final CouplesService _couplesService = CouplesService();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _hasCoupleAccount = false;
  CoupleAccount? _coupleAccount;
  String? _generatedInvitationToken;

  @override
  void initState() {
    super.initState();
    _loadCoupleAccount();

    // Handle deep link invitation
    if (widget.invitationToken != null) {
      _handleInvitationToken(widget.invitationToken!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupleAccount() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final account = await _couplesService.getActiveCoupleAccount(user.uid);
      setState(() {
        _hasCoupleAccount = account != null;
        _coupleAccount = account;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading couple account: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final token = await _couplesService.sendInvitation(
        currentUserId: user.uid,
        currentUserName: user.displayName ?? 'User',
        currentUserEmail: user.email ?? '',
        partnerEmail: _emailController.text.trim(),
      );

      setState(() {
        _generatedInvitationToken = token;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _emailController.clear();
        _loadCoupleAccount(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invitation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleInvitationToken(String token) async {
    final details = await _couplesService.getInvitationDetails(token);

    if (details == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showInvitationDialog(token, details);
    }
  }

  void _showInvitationDialog(String token, Map<String, dynamic> details) {
    final inviterName = details['inviterName'] as String;
    final inviterEmail = details['inviterEmail'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partner Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$inviterName ($inviterEmail) wants to connect with you on FinCoPilot!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'By accepting, you\'ll share your financial data with your partner.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _declineInvitation(token);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptInvitation(token);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(String token) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _couplesService.acceptInvitation(
        token: token,
        partnerId: user.uid,
        partnerName: user.displayName ?? 'User',
        partnerEmail: user.email ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted! You\'re now connected.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCoupleAccount(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting invitation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _declineInvitation(String token) async {
    setState(() => _isLoading = true);

    try {
      await _couplesService.declineInvitation(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining invitation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectCouple() async {
    if (_coupleAccount == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Couple Account'),
        content: const Text(
          'Are you sure you want to disconnect from your partner? This will stop sharing your financial data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _couplesService.disconnectCoupleAccount(
        coupleAccountId: _coupleAccount!.id,
        userId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couple account disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadCoupleAccount(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disconnecting: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyInvitationLink() {
    if (_generatedInvitationToken == null) return;

    final link = _couplesService.generateInvitationLink(_generatedInvitationToken!);
    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Couples Dashboard')),
        body: const Center(child: Text('Please sign in to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couples Dashboard'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(theme),
                  const SizedBox(height: 32),

                  // Main content based on couple status
                  if (_hasCoupleAccount && _coupleAccount != null)
                    _buildConnectedView(theme, user.uid)
                  else
                    _buildInviteView(theme),

                  // Generated invitation link
                  if (_generatedInvitationToken != null) ...[
                    const SizedBox(height: 24),
                    _buildInvitationLinkCard(theme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Couples Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your shared finances together',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInviteView(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Your Partner',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your financial journey with your partner. Track spending, set budgets, and achieve goals together.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Partner\'s Email',
                  hintText: 'partner@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendInvitation,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Invitation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView(ThemeData theme, String currentUserId) {
    final partnerId = _coupleAccount!.getPartnerId(currentUserId);
    final partnerUser = partnerId != null ? _coupleAccount!.getUser(partnerId) : null;
    final partnerName = partnerUser?.name ?? 'Partner';
    final visibilityLevel = _coupleAccount!.settings.visibility;

    return Column(
      children: [
        // Partner info card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.pink.withOpacity(0.2),
                      child: Text(
                        partnerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected with',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            partnerName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildSettingRow(
                  theme,
                  'Visibility',
                  visibilityLevel == VisibilityLevel.full ? 'Full Access' : 'Summary Only',
                  Icons.visibility,
                ),
                const SizedBox(height: 12),
                _buildSettingRow(
                  theme,
                  'Large Spend Alerts',
                  _coupleAccount!.settings.notifyOnLargeSpend ? 'Enabled' : 'Disabled',
                  Icons.notifications_active,
                ),
                if (_coupleAccount!.settings.notifyOnLargeSpend) ...[
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    theme,
                    'Alert Threshold',
                    '\$${_coupleAccount!.settings.largeSpendThreshold.toStringAsFixed(0)}',
                    Icons.attach_money,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to settings
                          Navigator.pushNamed(context, '/couples-settings');
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to couples dashboard
                          Navigator.pushNamed(context, '/couples-dashboard');
                        },
                        icon: const Icon(Icons.dashboard),
                        label: const Text('View Dashboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _disconnectCouple,
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    label: const Text(
                      'Disconnect',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationLinkCard(ThemeData theme) {
    final link = _couplesService.generateInvitationLink(_generatedInvitationToken!);

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Invitation Link Generated',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _copyInvitationLink,
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this link with your partner. Link expires in 7 days.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
