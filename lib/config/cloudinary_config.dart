class CloudinaryConfig {
  // Cloudinary Credentials
  // Get these from your Cloudinary Dashboard: https://cloudinary.com/console
  
  static const String cloudName = 'dm9oh76nw'; // Replace with your cloud name
  static const String apiKey = '721347191818166'; // Replace with your API key  
  static const String apiSecret = 'wyUx0GZFZV9LpwIPbjsu8AvKSUw'; // Replace with your API secret
  
  // Upload preset for unsigned uploads (recommended for mobile apps)
  static const String uploadPreset = 'shopradar_profiles'; // Create this in Cloudinary console
  
  // Security Note: 
  // For production apps, consider using environment variables or secure storage
  // instead of hardcoding credentials in the source code.
}
