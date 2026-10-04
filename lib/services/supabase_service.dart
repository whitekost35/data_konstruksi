import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker.dart';
import '../models/transaction.dart';
import '../models/attendance.dart';
import '../models/adjustment.dart';
import '../models/kasbon.dart';
import '../models/user_profile.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Profile Methods
  Future<UserProfile?> getUserProfile(String id) async {
    try {
      final data = await _client.from('app_profiles').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    await _client.from('app_profiles').upsert(profile.toMap());
  }

  Future<String?> uploadProfilePhoto(Uint8List bytes) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'avatars/$fileName';
    
    await _client.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
    
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<List<Worker>> getAllWorkers() async {
    try {
      // Try ordering by order_index, fallback to name if column missing or error
      final rows = await _client.from('gondes_workers').select().order('order_index', ascending: true);
      return (rows as List).map((e) => Worker.fromMap(Map<String,dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('Fallback to sorting by name: $e');
      final rows = await _client.from('gondes_workers').select().order('name');
      return (rows as List).map((e) => Worker.fromMap(Map<String,dynamic>.from(e))).toList();
    }
  }
  Stream<List<Worker>> getWorkersStream() => _client.from('gondes_workers').stream(primaryKey: ['id']).map((rows) => rows.map((e) => Worker.fromMap(e)).toList());
  Future<void> upsertWorker(Worker worker) => _client.from('gondes_workers').upsert(worker.toMap());
  Future<void> deleteWorker(String id) => _client.from('gondes_workers').delete().eq('id', id);

  Future<List<AttendanceRecord>> getAllAttendance() async {
    final rows = await _client.from('gondes_attendance').select();
    return (rows as List).map((e) => AttendanceRecord.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<List<AttendanceRecord>> getAttendanceForRange(String start, String end) async {
    final rows = await _client.from('gondes_attendance').select().gte('date', start).lte('date', end);
    return (rows as List).map((e) => AttendanceRecord.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> upsertAttendance(AttendanceRecord record) async {
    await _client.from('gondes_attendance').upsert({
      'worker_id': record.workerId, 
      'date': record.date, 
      'status': record.status.name.toUpperCase()
    }, onConflict: 'worker_id,date');
  }

  Future<List<WeeklyAdjustment>> getAllAdjustments() async {
    final rows = await _client.from('gondes_adjustments').select();
    return (rows as List).map((e) => WeeklyAdjustment.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<List<WeeklyAdjustment>> getAdjustmentsForWeek(String weekStart) async {
    final rows = await _client.from('gondes_adjustments').select().eq('week_start_date', weekStart);
    return (rows as List).map((e) => WeeklyAdjustment.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> upsertAdjustment(WeeklyAdjustment value) => _client.from('gondes_adjustments').upsert(value.toMap());

  Future<List<GlobalKasbonEntry>> getAllGlobalKasbon() async {
    final rows = await _client.from('gondes_kasbon_global').select().order('date', ascending: false);
    return (rows as List).map((e) => GlobalKasbonEntry.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<List<GlobalKasbonEntry>> getGlobalKasbon(String weekStart) async {
    final rows = await _client.from('gondes_kasbon_global').select().eq('week_start_date', weekStart).order('date', ascending: false);
    return (rows as List).map((e) => GlobalKasbonEntry.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> upsertGlobalKasbon(GlobalKasbonEntry value) => _client.from('gondes_kasbon_global').upsert(value.toMap());
  Future<void> deleteGlobalKasbon(String id) => _client.from('gondes_kasbon_global').delete().eq('id', id);

  Future<List<PrivateKasbonEntry>> getAllPrivateKasbon() async {
    final rows = await _client.from('gondes_kasbon_private').select().order('date', ascending: false);
    return (rows as List).map((e) => PrivateKasbonEntry.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<List<PrivateKasbonEntry>> getPrivateKasbon(String workerId) async {
    final rows = await _client.from('gondes_kasbon_private').select().eq('worker_id', workerId).order('date', ascending: false);
    return (rows as List).map((e) => PrivateKasbonEntry.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> upsertPrivateKasbon(PrivateKasbonEntry value) => _client.from('gondes_kasbon_private').upsert(value.toMap());
  Future<void> deletePrivateKasbon(String id) => _client.from('gondes_kasbon_private').delete().eq('id', id);

  Stream<List<PrivateKasbonEntry>> getPrivateKasbonStream() {
    return _client
        .from('gondes_kasbon_private')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((map) => PrivateKasbonEntry.fromMap(map)).toList());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final rows = await _client.from('transactions').select().order('date', ascending: false);
    return (rows as List).map((e) => Transaction.fromMap(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> upsertTransaction(Transaction value) => _client.from('transactions').upsert(value.toMap());
  Future<void> deleteTransaction(String id) => _client.from('transactions').delete().eq('id', id);

  Future<void> resetWeekData(String start, String end) async {
    await _client.from('gondes_attendance').delete().gte('date', start).lte('date', end);
    await _client.from('gondes_adjustments').delete().eq('week_start_date', start);
    await _client.from('gondes_kasbon_global').delete().eq('week_start_date', start);
  }

  // Auth Methods
  Future<String?> verifyPin(String pin) async {
    try {
      final res = await _client
          .from('app_auth')
          .select('role')
          .eq('pin', pin)
          .maybeSingle();
      
      if (res != null) return res['role'] as String;
      return null;
    } catch (e) {
      debugPrint('Auth error: $e');
      return null;
    }
  }
}
