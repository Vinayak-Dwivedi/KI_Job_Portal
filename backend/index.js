const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// Initialise Firebase Admin (Uses default credentials on server)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault()
  });
}

const app = express();

app.use(cors());
app.use(express.json());

const privacyRoutes = require('./routes/privacy.routes');
app.use('/api', privacyRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Privacy API server running on port ${PORT}`);
});
