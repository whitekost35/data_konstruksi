class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sjkhwgmkkcnwoxbplbxz.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_4g_CZ-aNbtSvWcY-Qa2fBg_jzw-Gkji',
  );
}
