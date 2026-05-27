const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referral.controller');

// POST Award Referral Reward
router.post('/referrals/award', referralController.awardReferral);

// GET Referral Stats for a user
router.get('/referrals/stats/:userId', referralController.getReferralStats);

module.exports = router;
