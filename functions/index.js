const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Weekly coaching tips (runs every Monday at 9 AM)
exports.sendWeeklyCoachingTips = functions.pubsub
  .schedule('0 9 * * 1')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Starting weekly coaching tips...');
    
    try {
      const users = await db.collection('users')
        .where('notification_settings.spending_insights', '==', true)
        .where('notification_settings.enabled', '==', true)
        .get();

      const coachingTips = [
        {
          title: '💡 Weekly Tip: The 50/30/20 Rule',
          body: 'Try allocating 50% for needs, 30% for wants, and 20% for savings. This simple rule can transform your budget!'
        },
        {
          title: '💰 Save on Groceries',
          body: 'Planning meals for the week? Make a shopping list and stick to it. You could save 20% on your grocery bill!'
        },
        {
          title: '📊 Track Your Progress',
          body: 'You\'ve been doing great! Check your spending trends and see how much you\'ve improved this month.'
        },
        {
          title: '🎯 Emergency Fund Goal',
          body: 'Aim to save $1,000 for emergencies first. Even $25 per week gets you there in less than a year!'
        }
      ];

      const randomTip = coachingTips[Math.floor(Math.random() * coachingTips.length)];
      const promises = [];

      for (const userDoc of users.docs) {
        const userData = userDoc.data();
        const token = userData.fcmToken;
        
        if (token) {
          const message = {
            token: token,
            notification: {
              title: randomTip.title,
              body: randomTip.body,
            },
            data: {
              type: 'coaching_tip',
              user_id: userDoc.id,
              category: 'weekly_tip',
            },
            android: {
              notification: {
                channelId: 'coaching_tips',
                icon: 'ic_launcher',
                color: '#4CAF50'
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1
                }
              }
            }
          };

          promises.push(
            messaging.send(message).then(() => {
              // Log notification to Firestore
              return db.collection('notifications').add({
                userId: userDoc.id,
                type: 'coaching_tip',
                title: randomTip.title,
                body: randomTip.body,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false,
                data: {
                  category: 'weekly_tip'
                }
              });
            }).catch(error => {
              console.error(`Error sending to ${userDoc.id}:`, error);
            })
          );
        }
      }

      await Promise.all(promises);
      console.log(`Sent weekly coaching tips to ${promises.length} users`);
      
    } catch (error) {
      console.error('Error sending weekly coaching tips:', error);
    }
  });

// Budget alerts (runs daily at 9 AM to check all users)
exports.checkDailyBudgetAlerts = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Starting daily budget alerts check...');
    
    try {
      const users = await db.collection('users')
        .where('notification_settings.budget_alerts', '==', true)
        .where('notification_settings.enabled', '==', true)
        .get();

      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      for (const userDoc of users.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const token = userData.fcmToken;
        
        if (!token) continue;

        try {
          // Get user's budgets for current month
          const budgetsSnapshot = await db.collection('budgets')
            .where('userId', '==', userId)
            .where('month', '==', `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}`)
            .get();

          for (const budgetDoc of budgetsSnapshot.docs) {
            const budgetData = budgetDoc.data();
            const category = budgetData.category;
            const budgetLimit = budgetData.amount;
            
            // Calculate current spending for this category
            const transactionsSnapshot = await db.collection('transactions')
              .where('userId', '==', userId)
              .where('category', '==', category)
              .where('type', '==', 'expense')
              .where('date', '>=', admin.firestore.Timestamp.fromDate(startOfMonth))
              .where('date', '<=', admin.firestore.Timestamp.fromDate(endOfMonth))
              .get();

            let currentSpending = 0;
            transactionsSnapshot.forEach(doc => {
              currentSpending += doc.data().amount;
            });

            const percentageUsed = (currentSpending / budgetLimit) * 100;
            let shouldSendAlert = false;
            let alertTitle = '';
            let alertBody = '';

            // Check for different alert thresholds
            if (percentageUsed >= 100 && !budgetData.overageAlertSent) {
              shouldSendAlert = true;
              alertTitle = '💸 Budget Exceeded!';
              alertBody = `You've overspent in ${category} by $${(currentSpending - budgetLimit).toFixed(2)}. Current: $${currentSpending.toFixed(2)} / $${budgetLimit.toFixed(2)}`;
              // Mark alert as sent
              await db.collection('budgets').doc(budgetDoc.id).update({
                overageAlertSent: true
              });
            } else if (percentageUsed >= 90 && !budgetData.ninetyPercentAlertSent) {
              shouldSendAlert = true;
              alertTitle = '⚠️ Budget Alert - 90% Used';
              alertBody = `You've used 90% of your ${category} budget. $${(budgetLimit - currentSpending).toFixed(2)} remaining.`;
              await db.collection('budgets').doc(budgetDoc.id).update({
                ninetyPercentAlertSent: true
              });
            } else if (percentageUsed >= 75 && !budgetData.seventyFivePercentAlertSent) {
              shouldSendAlert = true;
              alertTitle = '📊 Budget Alert - 75% Used';
              alertBody = `You've used 75% of your ${category} budget. $${(budgetLimit - currentSpending).toFixed(2)} remaining.`;
              await db.collection('budgets').doc(budgetDoc.id).update({
                seventyFivePercentAlertSent: true
              });
            }

            if (shouldSendAlert) {
              const message = {
                token: token,
                notification: {
                  title: alertTitle,
                  body: alertBody,
                },
                data: {
                  type: 'budget_alert',
                  user_id: userId,
                  category: category,
                  current_spending: currentSpending.toString(),
                  budget_limit: budgetLimit.toString(),
                  action: 'open_budget'
                },
                android: {
                  notification: {
                    channelId: 'budget_alerts',
                    icon: 'ic_launcher',
                    color: '#FF9800'
                  }
                },
                apns: {
                  payload: {
                    aps: {
                      sound: 'default',
                      badge: 1
                    }
                  }
                }
              };

              try {
                await messaging.send(message);
                
                // Log notification to Firestore
                await db.collection('notifications').add({
                  userId: userId,
                  type: 'budget_alert',
                  title: alertTitle,
                  body: alertBody,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  read: false,
                  data: {
                    category: category,
                    amount: currentSpending,
                    budgetLimit: budgetLimit,
                    action: 'open_budget'
                  }
                });

                console.log(`Budget alert sent to ${userId} for ${category}`);
              } catch (error) {
                console.error(`Error sending budget alert to ${userId}:`, error);
              }
            }
          }
        } catch (error) {
          console.error(`Error processing budget alerts for ${userId}:`, error);
        }
      }
      
      console.log('Daily budget alerts check completed');
      
    } catch (error) {
      console.error('Error in daily budget alerts:', error);
    }
  });

// Monthly budget reset (runs on the 1st of each month at midnight)
exports.resetMonthlyBudgetAlerts = functions.pubsub
  .schedule('0 0 1 * *')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Resetting monthly budget alert flags...');
    
    try {
      const budgetsSnapshot = await db.collection('budgets').get();
      const batch = db.batch();

      budgetsSnapshot.forEach(doc => {
        batch.update(doc.ref, {
          seventyFivePercentAlertSent: false,
          ninetyPercentAlertSent: false,
          overageAlertSent: false
        });
      });

      await batch.commit();
      console.log(`Reset alert flags for ${budgetsSnapshot.size} budgets`);
      
    } catch (error) {
      console.error('Error resetting budget alert flags:', error);
    }
  });

// Price drop alerts (runs twice daily to check for price changes)
exports.checkPriceDropAlerts = functions.pubsub
  .schedule('0 9,18 * * *')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Checking price drop alerts...');
    
    try {
      const users = await db.collection('users')
        .where('notification_settings.price_drops', '==', true)
        .where('notification_settings.enabled', '==', true)
        .get();

      for (const userDoc of users.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const token = userData.fcmToken;
        
        if (!token) continue;

        // Get user's price tracking items
        const trackedItemsSnapshot = await db.collection('price_tracking')
          .where('userId', '==', userId)
          .where('active', '==', true)
          .get();

        for (const itemDoc of trackedItemsSnapshot.docs) {
          const itemData = itemDoc.data();
          const itemName = itemData.itemName;
          const targetPrice = itemData.targetPrice;
          const lastKnownPrice = itemData.lastKnownPrice;
          
          // In a real implementation, you would fetch current prices from APIs
          // For demo purposes, we'll simulate a price drop
          const currentPrice = lastKnownPrice * (0.85 + Math.random() * 0.3); // Random price between 85-115% of last known
          
          if (currentPrice <= targetPrice && currentPrice < lastKnownPrice) {
            const message = {
              token: token,
              notification: {
                title: '🏷️ Price Drop Alert!',
                body: `Great news! ${itemName} dropped from $${lastKnownPrice.toFixed(2)} to $${currentPrice.toFixed(2)}!`,
              },
              data: {
                type: 'price_alert',
                user_id: userId,
                item_name: itemName,
                old_price: lastKnownPrice.toString(),
                new_price: currentPrice.toString(),
                action: 'open_price_alerts'
              },
              android: {
                notification: {
                  channelId: 'price_alerts',
                  icon: 'ic_launcher',
                  color: '#2196F3'
                }
              },
              apns: {
                payload: {
                  aps: {
                    sound: 'default',
                    badge: 1
                  }
                }
              }
            };

            try {
              await messaging.send(message);
              
              // Update the item's last known price
              await db.collection('price_tracking').doc(itemDoc.id).update({
                lastKnownPrice: currentPrice,
                lastChecked: admin.firestore.FieldValue.serverTimestamp()
              });

              // Log notification
              await db.collection('notifications').add({
                userId: userId,
                type: 'price_alert',
                title: '🏷️ Price Drop Alert!',
                body: `Great news! ${itemName} dropped from $${lastKnownPrice.toFixed(2)} to $${currentPrice.toFixed(2)}!`,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false,
                data: {
                  itemName: itemName,
                  oldPrice: lastKnownPrice,
                  newPrice: currentPrice,
                  action: 'open_price_alerts'
                }
              });

              console.log(`Price drop alert sent to ${userId} for ${itemName}`);
            } catch (error) {
              console.error(`Error sending price drop alert to ${userId}:`, error);
            }
          }
        }
      }
      
      console.log('Price drop alerts check completed');
      
    } catch (error) {
      console.error('Error checking price drop alerts:', error);
    }
  });

// Milestone achievements (runs daily to check for achievements)
exports.checkMilestoneAchievements = functions.pubsub
  .schedule('0 20 * * *')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Checking milestone achievements...');
    
    try {
      const users = await db.collection('users')
        .where('notification_settings.enabled', '==', true)
        .get();

      const milestones = [100, 500, 1000, 5000, 10000, 25000, 50000];

      for (const userDoc of users.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const token = userData.fcmToken;
        
        if (!token) continue;

        try {
          // Calculate total spending
          const transactionsSnapshot = await db.collection('transactions')
            .where('userId', '==', userId)
            .where('type', '==', 'expense')
            .get();

          let totalSpending = 0;
          transactionsSnapshot.forEach(doc => {
            totalSpending += doc.data().amount;
          });

          // Check for milestone achievements
          for (const milestone of milestones) {
            if (totalSpending >= milestone) {
              const achievementDoc = await db.collection('achievements')
                .doc(`${userId}_spending_${milestone}`)
                .get();

              if (!achievementDoc.exists) {
                // New milestone achieved!
                const message = {
                  token: token,
                  notification: {
                    title: '🎉 Milestone Achieved!',
                    body: `You've reached $${milestone} in total spending! Your current total: $${totalSpending.toFixed(2)}`,
                  },
                  data: {
                    type: 'milestone',
                    user_id: userId,
                    milestone_type: 'spending',
                    milestone_value: milestone.toString(),
                    total_spending: totalSpending.toString(),
                    action: 'open_achievements'
                  },
                  android: {
                    notification: {
                      channelId: 'milestones',
                      icon: 'ic_launcher',
                      color: '#9C27B0'
                    }
                  },
                  apns: {
                    payload: {
                      aps: {
                        sound: 'default',
                        badge: 1
                      }
                    }
                  }
                };

                try {
                  await messaging.send(message);
                  
                  // Mark milestone as achieved
                  await db.collection('achievements').doc(`${userId}_spending_${milestone}`).set({
                    userId: userId,
                    type: 'spending_milestone',
                    milestone: milestone,
                    totalSpending: totalSpending,
                    achievedAt: admin.firestore.FieldValue.serverTimestamp()
                  });

                  // Log notification
                  await db.collection('notifications').add({
                    userId: userId,
                    type: 'milestone',
                    title: '🎉 Milestone Achieved!',
                    body: `You've reached $${milestone} in total spending! Your current total: $${totalSpending.toFixed(2)}`,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    read: false,
                    data: {
                      milestoneType: 'spending',
                      milestone: milestone,
                      totalSpending: totalSpending,
                      action: 'open_achievements'
                    }
                  });

                  console.log(`Milestone achievement sent to ${userId} for $${milestone}`);
                } catch (error) {
                  console.error(`Error sending milestone alert to ${userId}:`, error);
                }
              }
            }
          }
        } catch (error) {
          console.error(`Error processing milestones for ${userId}:`, error);
        }
      }
      
      console.log('Milestone achievements check completed');
      
    } catch (error) {
      console.error('Error checking milestone achievements:', error);
    }
  });

// Cleanup old notifications (runs weekly)
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 2 * * 0')
  .timeZone('America/Toronto')
  .onRun(async (context) => {
    console.log('Cleaning up old notifications...');
    
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 days ago
      
      const oldNotificationsSnapshot = await db.collection('notifications')
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();

      const batch = db.batch();
      oldNotificationsSnapshot.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${oldNotificationsSnapshot.size} old notifications`);
      
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
    }
  });