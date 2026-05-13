const admin = require('firebase-admin');

// Helper to get Firestore instance
const db = () => admin.firestore();

// 1. Get Privacy Settings
exports.getPrivacySettings = async (req, res) => {
  try {
    const { userId } = req.params;
    const doc = await db().collection('privacy_settings').doc(userId).get();

    if (!doc.exists) {
      // Return defaults
      return res.json({
        userId,
        publicProfile: true,
        showLocation: true,
        showPhoneNumber: false,
        showEmail: true
      });
    }

    res.json(doc.data());
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 2. Update Privacy Settings
exports.updatePrivacySettings = async (req, res) => {
  try {
    const { userId, publicProfile, showLocation, showPhoneNumber, showEmail } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    const updateData = {
      userId,
      publicProfile: publicProfile ?? true,
      showLocation: showLocation ?? true,
      showPhoneNumber: showPhoneNumber ?? false,
      showEmail: showEmail ?? true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db().collection('privacy_settings').doc(userId).set(updateData, { merge: true });

    res.json({ message: 'Privacy settings updated successfully', data: updateData });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 3. Get Filtered User Profile
exports.getFilteredProfile = async (req, res) => {
  try {
    const { targetUid } = req.params;
    const { viewerUid } = req.query; // Passed from frontend auth context

    if (!targetUid) {
      return res.status(400).json({ error: 'targetUid is required' });
    }

    const userDoc = await db().collection('users').doc(targetUid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    
    // Fetch Target User Privacy Settings
    const privacyDoc = await db().collection('privacy_settings').doc(targetUid).get();
    const privacy = privacyDoc.exists ? privacyDoc.data() : {
      publicProfile: true,
      showLocation: true,
      showPhoneNumber: false,
      showEmail: true
    };

    // Rule 1: Public Profile Enforcement
    if (!privacy.publicProfile && viewerUid !== targetUid) {
      return res.status(403).json({ error: 'Profile is private' });
    }

    const filteredData = {
      uid: userData.uid,
      name: userData.name,
      role: userData.role,
      bio: userData.bio,
      profilePhotoUrl: userData.profilePhotoUrl,
    };

    // Rule 2: Location Visibility
    if (privacy.showLocation || viewerUid === targetUid) {
      filteredData.location = userData.location;
      filteredData.latitude = userData.latitude;
      filteredData.longitude = userData.longitude;
    }

    // Rule 3: Email Visibility
    if (privacy.showEmail || viewerUid === targetUid) {
      filteredData.email = userData.email;
    }

    // Rule 4: Phone Number Visibility + Verified Contact Logic
    let allowPhone = viewerUid === targetUid;

    if (!allowPhone && privacy.showPhoneNumber) {
      // Check if verified contact
      const contactId = [viewerUid, targetUid].sort().join('_');
      const contactDoc = await db().collection('contacts').doc(contactId).get();
      if (contactDoc.exists && contactDoc.data().isVerified) {
        allowPhone = true;
      }
    }

    if (allowPhone) {
      filteredData.phone = userData.phone;
    }

    res.json(filteredData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 4. Mutual Interaction / Verified Contact Handler
exports.addVerifiedContact = async (req, res) => {
  try {
    const { user1, user2 } = req.body;

    if (!user1 || !user2) {
      return res.status(400).json({ error: 'Both user IDs required' });
    }

    const contactId = [user1, user2].sort().join('_');
    const contactData = {
      user1,
      user2,
      isVerified: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db().collection('contacts').doc(contactId).set(contactData);
    res.json({ message: 'Verified contact added', data: contactData });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 5. Get Verification Documents
exports.getVerificationDocs = async (req, res) => {
  try {
    const { userId } = req.params;
    const doc = await db().collection('verification_docs').doc(userId).get();

    if (!doc.exists) {
      return res.json([
        { name: 'Aadhar Card', status: 'Verified' },
        { name: 'Trade Certificate', status: 'Not Uploaded' }
      ]);
    }

    const data = doc.data();
    const docs = [
      { name: 'Aadhar Card', status: data.aadharStatus || 'Verified' },
      { name: 'Trade Certificate', status: data.tradeStatus || 'Not Uploaded' }
    ];
    res.json(docs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 6. Upload/Update Verification Document
exports.uploadVerificationDoc = async (req, res) => {
  try {
    const { userId, documentName } = req.body;

    if (!userId || !documentName) {
      return res.status(400).json({ error: 'userId and documentName are required' });
    }

    const updateData = {};
    if (documentName === 'Aadhar Card') {
      updateData.aadharStatus = 'Pending';
    } else if (documentName === 'Trade Certificate') {
      updateData.tradeStatus = 'Pending';
    } else {
      return res.status(400).json({ error: 'Invalid document name' });
    }

    await db().collection('verification_docs').doc(userId).set(updateData, { merge: true });

    res.json({ message: 'Document uploaded successfully', documentName, status: 'Pending' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
