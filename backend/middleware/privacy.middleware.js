const admin = require('firebase-admin');

exports.enforcePublicSearch = async (req, res, next) => {
  try {
    const db = admin.firestore();
    
    // Fetch all privacy docs where publicProfile is false
    const snapshot = await db.collection('privacy_settings')
      .where('publicProfile', '==', false)
      .get();

    const privateUids = snapshot.docs.map(doc => doc.id);
    
    // Expose excluded uids on the request object
    req.privateUids = privateUids;
    
    next();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
