// This script extracts the Supabase configuration from the HTML injected values
// and makes it available to the Flutter app

document.addEventListener('DOMContentLoaded', function() {
  // Make sure the supabaseConfig from the HTML is accessible to Flutter
  if (window.supabaseConfig) {
    console.log('Supabase config loaded from HTML');
  } else {
    console.error('Supabase config not found in HTML');
  }
});

// Provide a function to manually set Supabase config if needed
window.setSupabaseConfig = function(url, key) {
  window.supabaseConfig = {
    url: url,
    key: key
  };
  console.log('Supabase config manually set');
};
