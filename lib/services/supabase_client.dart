import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://psqukxxunstveqyhodxe.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzcXVreHh1bnN0dmVxeWhvZHhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAxMTE3MTksImV4cCI6MjA0NTY4NzcxOX0.Q_g9uIWP-ina87uxi4so-26unHr-Rmu469FBPsjI8DI',
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}
