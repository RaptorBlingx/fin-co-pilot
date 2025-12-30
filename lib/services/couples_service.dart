import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/couple_account.dart';
import '../models/notification.dart' as models;

/// Service for managing couple accounts and partner invitations
///
/// Features:
/// - Send partner invitations (email or shareable link)
/// - Accept/decline invitations
/// - Manage shared visibility settings
/// - Connect/disconnect couple accounts
/// - Week 11 feature: Couples Dashboard
class CouplesService {
  static final CouplesService _instance = CouplesService._internal();
  factory CouplesService() => _instance;
  CouplesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================================================================
  // INVITATION MANAGEMENT
  // =================================================================

  /// Send partner invitation via email or link
  Future<String> sendInvitation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserEmail,
    required String partnerEmail,
    String partnerName = '',
  }) async {
    try {
      print('📨 Sending couple invitation to $partnerEmail...');

      // Generate unique invitation token (timestamp-based UUID)
      final invitationToken = '${DateTime.now().millisecondsSinceEpoch}_${currentUserId.substring(0, 8)}';
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7)); // 7-day expiration

      // Check if couple account already exists with this email
      final existingAccount = await _findExistingCoupleAccount(
        currentUserId,
        partnerEmail,
      );

      if (existingAccount != null) {
        if (existingAccount.settings.visibility == VisibilityLevel.full) {
          throw Exception('You are already connected with this partner');
        } else {
          // Resend invitation
          await _firestore.collection('couple_accounts').doc(existingAccount.id).update({
            'invitationToken': invitationToken,
            'invitationSentAt': Timestamp.fromDate(now),
            'invitationExpiresAt': Timestamp.fromDate(expiresAt),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Invitation resent with token: $invitationToken');
          return invitationToken;
        }
      }

      // Create new couple account in pending state
      final coupleAccountData = {
        'users': {
          currentUserId: CoupleUser(
            name: currentUserName,
            role: CoupleRole.initiator,
            joinedAt: now,
          ).toMap(),
          'pending_partner': {
            'name': partnerName,
            'email': partnerEmail,
            'role': CoupleRole.partner.name,
            'invitationToken': invitationToken,
            'invitationSentAt': Timestamp.fromDate(now),
            'invitationExpiresAt': Timestamp.fromDate(expiresAt),
          },
        },
        'sharedBudgets': [],
        'sharedCategories': [],
        'settings': CoupleAccountSettings(
          visibility: VisibilityLevel.summary, // Default to summary until accepted
          notifyOnLargeSpend: true,
          largeSpendThreshold: 100.0,
        ).toMap(),
        'conflicts': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('couple_accounts').add(coupleAccountData);

      // Store invitation in separate collection for easy lookup
      await _firestore.collection('couple_invitations').doc(invitationToken).set({
        'coupleAccountId': docRef.id,
        'inviterId': currentUserId,
        'inviterName': currentUserName,
        'inviterEmail': currentUserEmail,
        'partnerEmail': partnerEmail,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      print('✅ Couple invitation sent successfully');
      print('📋 Invitation token: $invitationToken');
      print('⏰ Expires at: $expiresAt');

      return invitationToken;
    } catch (e) {
      print('❌ Error sending invitation: $e');
      rethrow;
    }
  }

  /// Get invitation details from token
  Future<Map<String, dynamic>?> getInvitationDetails(String token) async {
    try {
      final doc = await _firestore.collection('couple_invitations').doc(token).get();

      if (!doc.exists) {
        print('❌ Invitation not found');
        return null;
      }

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        print('❌ Invitation expired');
        return null;
      }

      if (data['status'] != 'pending') {
        print('❌ Invitation already ${data['status']}');
        return null;
      }

      return data;
    } catch (e) {
      print('❌ Error getting invitation details: $e');
      return null;
    }
  }

  /// Accept partner invitation
  Future<void> acceptInvitation({
    required String token,
    required String partnerId,
    required String partnerName,
    required String partnerEmail,
  }) async {
    try {
      print('✅ Accepting couple invitation...');

      final invitationDetails = await getInvitationDetails(token);
      if (invitationDetails == null) {
        throw Exception('Invalid or expired invitation');
      }

      final coupleAccountId = invitationDetails['coupleAccountId'] as String;
      final inviterId = invitationDetails['inviterId'] as String;
      final now = DateTime.now();

      // Update couple account with partner details
      final coupleAccountRef = _firestore.collection('couple_accounts').doc(coupleAccountId);
      final coupleDoc = await coupleAccountRef.get();

      if (!coupleDoc.exists) {
        throw Exception('Couple account not found');
      }

      final coupleData = coupleDoc.data()!;
      final users = Map<String, dynamic>.from(coupleData['users'] as Map);

      // Replace pending partner with actual user
      users.remove('pending_partner');
      users[partnerId] = CoupleUser(
        name: partnerName,
        role: CoupleRole.partner,
        joinedAt: now,
      ).toMap();

      // Update to full visibility now that invitation is accepted
      await coupleAccountRef.update({
        'users': users,
        'settings.visibility': VisibilityLevel.full.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark invitation as accepted
      await _firestore.collection('couple_invitations').doc(token).update({
        'status': 'accepted',
        'partnerId': partnerId,
        'acceptedAt': Timestamp.fromDate(now),
      });

      // Send notification to inviter
      await _firestore.collection('notifications').add({
        'userId': inviterId,
        'type': models.NotificationType.couples.name,
        'priority': models.NotificationPriority.high.name,
        'title': 'Partner Connected!',
        'body': '$partnerName accepted your couple account invitation',
        'data': {
          'coupleAccountId': coupleAccountId,
          'partnerId': partnerId,
        },
        'read': false,
        'sentAt': Timestamp.fromDate(now),
      });

      print('✅ Couple account activated successfully');
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Decline partner invitation
  Future<void> declineInvitation(String token) async {
    try {
      print('❌ Declining couple invitation...');

      final invitationDetails = await getInvitationDetails(token);
      if (invitationDetails == null) {
        throw Exception('Invalid or expired invitation');
      }

      final inviterId = invitationDetails['inviterId'] as String;
      final partnerEmail = invitationDetails['partnerEmail'] as String;
      final now = DateTime.now();

      // Mark invitation as declined
      await _firestore.collection('couple_invitations').doc(token).update({
        'status': 'declined',
        'declinedAt': Timestamp.fromDate(now),
      });

      // Send notification to inviter
      await _firestore.collection('notifications').add({
        'userId': inviterId,
        'type': models.NotificationType.couples.name,
        'priority': models.NotificationPriority.medium.name,
        'title': 'Invitation Declined',
        'body': '$partnerEmail declined your couple account invitation',
        'data': {
          'token': token,
        },
        'read': false,
        'sentAt': Timestamp.fromDate(now),
      });

      print('✅ Invitation declined');
    } catch (e) {
      print('❌ Error declining invitation: $e');
      rethrow;
    }
  }

  // =================================================================
  // COUPLE ACCOUNT MANAGEMENT
  // =================================================================

  /// Get active couple account for user
  Future<CoupleAccount?> getActiveCoupleAccount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('couple_accounts')
          .where('users.$userId', isNotEqualTo: null)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return CoupleAccount.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Error getting couple account: $e');
      return null;
    }
  }

  /// Stream active couple account for user
  Stream<CoupleAccount?> streamActiveCoupleAccount(String userId) {
    return _firestore
        .collection('couple_accounts')
        .where('users.$userId', isNotEqualTo: null)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CoupleAccount.fromFirestore(snapshot.docs.first);
    });
  }

  /// Update visibility settings
  Future<void> updateVisibilitySettings({
    required String coupleAccountId,
    required VisibilityLevel visibility,
    required bool notifyOnLargeSpend,
    required double largeSpendThreshold,
  }) async {
    try {
      await _firestore.collection('couple_accounts').doc(coupleAccountId).update({
        'settings.visibility': visibility.name,
        'settings.notifyOnLargeSpend': notifyOnLargeSpend,
        'settings.largeSpendThreshold': largeSpendThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Visibility settings updated');
    } catch (e) {
      print('❌ Error updating visibility settings: $e');
      rethrow;
    }
  }

  /// Disconnect couple account
  Future<void> disconnectCoupleAccount({
    required String coupleAccountId,
    required String userId,
  }) async {
    try {
      print('💔 Disconnecting couple account...');

      final coupleDoc = await _firestore.collection('couple_accounts').doc(coupleAccountId).get();

      if (!coupleDoc.exists) {
        throw Exception('Couple account not found');
      }

      final coupleAccount = CoupleAccount.fromFirestore(coupleDoc);
      final partnerId = coupleAccount.getPartnerId(userId);

      if (partnerId == null) {
        throw Exception('Partner not found');
      }

      final now = DateTime.now();

      // Archive the couple account instead of deleting
      await _firestore.collection('couple_accounts').doc(coupleAccountId).update({
        'status': 'disconnected',
        'disconnectedAt': Timestamp.fromDate(now),
        'disconnectedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify partner
      await _firestore.collection('notifications').add({
        'userId': partnerId,
        'type': models.NotificationType.couples.name,
        'priority': models.NotificationPriority.high.name,
        'title': 'Couple Account Disconnected',
        'body': 'Your partner has disconnected your shared couple account',
        'data': {
          'coupleAccountId': coupleAccountId,
        },
        'read': false,
        'sentAt': Timestamp.fromDate(now),
      });

      print('✅ Couple account disconnected');
    } catch (e) {
      print('❌ Error disconnecting couple account: $e');
      rethrow;
    }
  }

  /// Check if user is in a couple
  Future<bool> isInCouple(String userId) async {
    final coupleAccount = await getActiveCoupleAccount(userId);
    return coupleAccount != null;
  }

  // =================================================================
  // HELPER METHODS
  // =================================================================

  /// Find existing couple account with partner
  Future<CoupleAccount?> _findExistingCoupleAccount(
    String userId,
    String partnerEmail,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('couple_accounts')
          .where('users.$userId', isNotEqualTo: null)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final users = data['users'] as Map<String, dynamic>;

        // Check if pending partner has this email
        final pendingPartner = users['pending_partner'];
        if (pendingPartner != null && pendingPartner['email'] == partnerEmail) {
          return CoupleAccount.fromFirestore(doc);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding existing couple account: $e');
      return null;
    }
  }

  /// Generate shareable invitation link
  String generateInvitationLink(String token) {
    // In production, this would be your app's deep link
    return 'fincopilot://invite/couple/$token';
  }
}
