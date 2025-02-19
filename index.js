var admin = require("firebase-admin");

// Provide the correct relative path to the serviceAccountKey.json file
var serviceAccount = require("./config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://pawsmatch-c5390-default-rtdb.firebaseio.com"
});