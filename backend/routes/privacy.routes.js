const express = require('express');
const router = express.Router();
const privacyController = require('../controllers/privacy.controller');

// GET User Privacy Settings
router.get('/privacy-settings/:userId', privacyController.getPrivacySettings);

// PUT User Privacy Settings
router.put('/privacy-settings', privacyController.updatePrivacySettings);

// GET Filtered User Profile (Enforced View)
router.get('/profile/:targetUid', privacyController.getFilteredProfile);

// POST Connect Verified Contacts
router.post('/contacts/verify', privacyController.addVerifiedContact);

// GET Verification Documents
router.get('/verification-docs/:userId', privacyController.getVerificationDocs);

// POST Upload Verification Document
router.post('/verification-docs/upload', privacyController.uploadVerificationDoc);

module.exports = router;
