// scripts/replace_env_placeholders.js
// This script replaces %PLACEHOLDER% in web/index.html with environment variables

const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, '../web/index.html');

const replacements = {
  '%FIREBASE_API_KEY%': process.env.FIREBASE_API_KEY || '',
  '%FIREBASE_APP_ID_WEB%': process.env.FIREBASE_APP_ID_WEB || '',
  '%FIREBASE_MESSAGING_SENDER_ID%': process.env.FIREBASE_MESSAGING_SENDER_ID || '',
  '%FIREBASE_PROJECT_ID%': process.env.FIREBASE_PROJECT_ID || '',
  '%FIREBASE_AUTH_DOMAIN%': process.env.FIREBASE_AUTH_DOMAIN || '',
  '%FIREBASE_DATABASE_URL%': process.env.FIREBASE_DATABASE_URL || '',
  '%FIREBASE_STORAGE_BUCKET%': process.env.FIREBASE_STORAGE_BUCKET || '',
  '%FIREBASE_MEASUREMENT_ID%': process.env.FIREBASE_MEASUREMENT_ID || '',
  '%SUPABASE_URL%': process.env.SUPABASE_URL || '',
  '%SUPABASE_KEY%': process.env.SUPABASE_KEY || '',
};

let content = fs.readFileSync(indexPath, 'utf8');
for (const [placeholder, value] of Object.entries(replacements)) {
  content = content.replace(new RegExp(placeholder, 'g'), value);
}
fs.writeFileSync(indexPath, content, 'utf8');
console.log('Environment placeholders replaced in web/index.html');
