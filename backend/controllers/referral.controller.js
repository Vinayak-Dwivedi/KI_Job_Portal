const admin = require('firebase-admin');

const db = () => admin.firestore();

/**
 * 1. Award Referral Reward
 * Validates and credits the referrer when a new user signs up.
 */
exports.awardReferral = async (req, res) => {
  try {
    const { referrerUid, referredUid } = req.body;

    if (!referrerUid || !referredUid) {
      return res.status(400).json({ error: 'referrerUid and referredUid are required' });
    }

    if (referrerUid === referredUid) {
      return res.status(400).json({ error: 'Self-referral is not allowed' });
    }

    // 1. Get Referral Settings
    const settingsDoc = await db().collection('settings').doc('referrals').get();
    const settings = settingsDoc.exists ? settingsDoc.data() : {
      isActive: true,
      bonusPerReferral: 100,
      maxReferralsPerUser: 0,
      validityWindowDays: 30
    };

    if (!settings.isActive) {
      return res.status(403).json({ error: 'Referral program is currently disabled' });
    }

    // 2. Check if already referred
    const referredUserDoc = await db().collection('users').doc(referredUid).get();
    if (!referredUserDoc.exists) {
      return res.status(404).json({ error: 'Referred user not found' });
    }
    
    const referredData = referredUserDoc.data();
    if (referredData.referredBy) {
      return res.status(400).json({ error: 'User already referred' });
    }

    // 3. Validate Referrer
    const referrerDoc = await db().collection('users').doc(referrerUid).get();
    if (!referrerDoc.exists) {
      return res.status(404).json({ error: 'Referrer not found' });
    }

    const referrerData = referrerDoc.data();
    
    // 4. Check Max Referrals Cap
    if (settings.maxReferralsPerUser > 0) {
      const referralCount = referrerData.referralCount || 0;
      if (referralCount >= settings.maxReferralsPerUser) {
        return res.status(403).json({ error: 'Referrer has reached the maximum referral cap' });
      }
    }

    // 5. Atomic Transaction: Award Credits and Log Referral
    const batch = db().batch();

    // Update Referrer
    const referrerRef = db().collection('users').doc(referrerUid);
    batch.update(referrerRef, {
      credits: admin.firestore.FieldValue.increment(settings.bonusPerReferral),
      referralCount: admin.firestore.FieldValue.increment(1),
      totalReferralCredits: admin.firestore.FieldValue.increment(settings.bonusPerReferral)
    });

    // Update Referred User
    const referredRef = db().collection('users').doc(referredUid);
    batch.update(referredRef, {
      referredBy: referrerUid
    });

    // Log Referral Event
    const referralLogRef = db().collection('referrals').doc();
    batch.set(referralLogRef, {
      referrerUid,
      referrerName: referrerData.name || 'Anonymous',
      referredUid,
      referredName: referredData.name || 'New User',
      bonusAmount: settings.bonusPerReferral,
      status: 'paid',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log Credit Transaction
    const transactionRef = db().collection('contactCredits').doc(referrerUid).collection('transactions').doc();
    batch.set(transactionRef, {
      title: 'Referral Reward',
      description: `Earned for referring ${referredData.name || 'a new user'}`,
      amount: settings.bonusPerReferral,
      type: 'credit',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();

    // 6. Send Push Notification
    try {
      if (referrerData.fcmToken) {
        const message = {
          notification: {
            title: '🎉 Referral Reward!',
            body: `You earned ${settings.bonusPerReferral} credits! ${referredData.name || 'Someone'} joined using your link.`
          },
          token: referrerData.fcmToken
        };
        await admin.messaging().send(message);
      }
    } catch (notifError) {
      console.error('Push notification failed:', notifError);
      // Don't fail the whole request if notification fails
    }

    res.json({ 
      success: true, 
      message: 'Referral awarded successfully',
      creditsAwarded: settings.bonusPerReferral
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * 2. Get Referral Stats for a user
 */
exports.getReferralStats = async (req, res) => {
  try {
    const { userId } = req.params;
    const userDoc = await db().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const data = userDoc.data();
    res.json({
      referralCount: data.referralCount || 0,
      totalReferralCredits: data.totalReferralCredits || 0,
      referralCode: data.referralCode || ''
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
