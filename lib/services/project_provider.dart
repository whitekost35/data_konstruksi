import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/worker.dart';
import '../models/attendance.dart';
import '../models/adjustment.dart';
import '../models/transaction.dart';
import '../models/kasbon.dart';
import '../models/period.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class WorkerWeeklyData {
  final Worker worker;
  final Map<String, AttendanceStatus> attendance;
  final WeeklyAdjustment? adjustment;
  WorkerWeeklyData({required this.worker, required this.attendance, this.adjustment});
  double get totalDays => attendance.values.fold(0, (s, v) => s + v.value);
  double get baseWageTotal => totalDays * worker.baseWage;
  double get overtimeBonus => 
      attendance.values.where((s) => s == AttendanceStatus.lembur1).length * 50000.0 + 
      attendance.values.where((s) => s == AttendanceStatus.lembur2).length * 75000.0 +
      attendance.values.where((s) => s == AttendanceStatus.lemburEkstra).length * worker.baseWage;
  double get weeklyTotal => baseWageTotal + overtimeBonus + (adjustment?.manualOvertime ?? 0);
  double get netWeeklyTotal => weeklyTotal - (adjustment?.privateKasbon ?? 0);
}

class ProjectProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  DateTime _currentWeekStart = _sunday(DateTime.now());
  static DateTime _sunday(DateTime d) => DateTime(d.year,d.month,d.day).subtract(Duration(days: d.weekday % 7));
  DateTime get currentWeekStart => _currentWeekStart;
  DateTime get currentWeekEnd => _currentWeekStart.add(const Duration(days:6));

  List<Worker> _workers=[];
  List<AttendanceRecord> _attendance=[];
  List<WeeklyAdjustment> _adjustments=[];
  List<Transaction> _transactions=[];
  List<PrivateKasbonEntry> _privateKasbon=[];
  List<GlobalKasbonEntry> _globalKasbon=[];
  UserProfile? _userProfile;
  String? _lastProfileId;
  bool _isLoading=false, _isSyncing=false;
  String? _lastError;
  bool get isLoading=>_isLoading; bool get isSyncing=>_isSyncing; String? get lastError=>_lastError;
  UserProfile? get userProfile => _userProfile;

  final List<ProjectPeriod> _periods = [
    ProjectPeriod(id:'p1',name:'Periode 1',dateRange:'06 Agustus 2024 - 20 Februari 2025',totalAmount:0,colorHex:'#4CAF50'),
    ProjectPeriod(id:'p2',name:'Periode 2',dateRange:'21 Februari 2025 - 05 Juli 2025',totalAmount:0,colorHex:'#2196F3'),
    ProjectPeriod(id:'p3',name:'Periode 3',dateRange:'05 Juli 2025 - 04 April 2026',totalAmount:0,colorHex:'#FF9800'),
    ProjectPeriod(id:'p4',name:'Periode 4',dateRange:'13 Mei 2026 - Saat Ini',totalAmount:0,isActive:true,colorHex:'#007AFF'),
    ProjectPeriod(id:'mykost',name:'Mykost',dateRange:'03 Juli 2025 - 12 Mei 2026',totalAmount:0,colorHex:'#9C27B0'),
  ];
  List<ProjectPeriod> get periods=>_periods;
  ProjectPeriod? get activePeriod=>_periods.firstWhere((p)=>p.isActive,orElse:()=>_periods.last);
  List<Worker> get workers=>_workers;
  List<Transaction> get recentTransactions=>List.unmodifiable(_transactions);
  List<PrivateKasbonEntry> get allPrivateKasbon=>List.unmodifiable(_privateKasbon);
  
  // Filter global kasbon based on the current selected week
  List<GlobalKasbonEntry> get globalKasbonEntries => 
      _globalKasbon.where((e) => e.weekStartDate == weekStartString).toList();

  String get weekStartString=>DateFormat('yyyy-MM-dd').format(_currentWeekStart);
  String get weekEndString=>DateFormat('yyyy-MM-dd').format(currentWeekEnd);

  double get grandTotalExpenditure=>_transactions.where((t)=>t.category!='Bumimas_Belanja').fold(0,(s,t)=>s+t.amount.abs());
  double get totalWeeklyWages=>workerWeeklyData.fold(0,(s,d)=>s+d.weeklyTotal);
  double get totalNetWeeklyWages=>workerWeeklyData.fold(0,(s,d)=>s+d.netWeeklyTotal);
  double get totalOutstandingKasbon=>_privateKasbon.fold(0,(s,e)=>s+(e.loanAmount-e.paymentAmount));

  double get totalBumimasBelanja => _transactions.where((t) => t.category == 'Bumimas_Belanja').fold(0, (s, t) => s + t.amount.abs());
  double get totalBumimasLunas => _transactions.where((t) => t.category == 'Bumimas_Lunas').fold(0, (s, t) => s + t.amount.abs());
  double get totalBumimasHutang => totalBumimasBelanja - totalBumimasLunas;

  double get activePeriodOtherTotal => _transactions
      .where((t) => t.periodId.toLowerCase().trim() == (activePeriod?.id.toLowerCase().trim() ?? 'p4') && t.matchesCategory('Lain-lain'))
      .fold(0.0, (s, t) => s + t.amount.abs());
  
  // Calculate total for the current week only
  double get globalKasbonTotal => globalKasbonEntries.fold(0,(s,e)=>s+e.amount);

  List<WorkerWeeklyData> get workerWeeklyData {
    final activeWorkers = _workers.where((w) => w.isActive).toList();

    // Smart Sorting: Gondes -> Tukang -> Kenek -> Others
    activeWorkers.sort((a, b) {
      int getPriority(Worker w) {
        if (w.name.toUpperCase().contains('GONDES')) return 0;
        if (w.role == WorkerRole.tukang) return 1;
        if (w.role == WorkerRole.kenek) return 2;
        return 3;
      }

      final pA = getPriority(a);
      final pB = getPriority(b);

      if (pA != pB) return pA.compareTo(pB);
      return a.name.compareTo(b.name); // Alphabetical within same priority
    });

    return activeWorkers.map((w) {
      final map = <String, AttendanceStatus>{};
      // Filter attendance for current week range
      final weekRecords = _attendance.where((r) {
        final rd = parseDate(r.date);
        if (rd == null) return false;
        return r.workerId == w.id &&
            !rd.isBefore(_currentWeekStart) &&
            !rd.isAfter(currentWeekEnd);
      });
      for (final r in weekRecords) map[r.date] = r.status;

      // Filter adjustments for current week start
      WeeklyAdjustment? adj;
      for (final x in _adjustments.where((x) => x.workerId == w.id && x.weekStartDate == weekStartString)) {
        adj = x;
        break;
      }
      return WorkerWeeklyData(worker: w, attendance: map, adjustment: adj);
    }).toList();
  }

  Map<String,double> get periodTotals=>{for(final p in _periods) p.name:_transactions.where((t)=>t.periodId.toLowerCase()==p.id.toLowerCase()&&t.category!='Bumimas_Belanja').fold(0.0,(s,t)=>s+t.amount.abs())};

  ProjectProvider(){refreshData();}
  DateTime? parseDate(String raw){
    final s=raw.trim();
    if (s.isEmpty) return null;
    
    // Coba format umum dulu
    for(final f in ['dd/MM/yyyy','dd MMM yyyy','dd MMMM yyyy','yyyy-MM-dd']){
      try {
        return DateFormat(f, 'id_ID').parseStrict(s);
      } catch (_) {}
    }
    
    // Fallback parsing manual untuk format dengan separator
    final parts = s.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      
      if (p0 != null && p1 != null && p2 != null) {
        // Deteksi apakah YYYY-MM-DD atau DD-MM-YYYY
        if (p0 > 1000) { // Asumsi YYYY-MM-DD
          return DateTime(p0, p1, p2);
        } else if (p2 > 1000) { // Asumsi DD-MM-YYYY atau MM-DD-YYYY (pilih DD-MM-YYYY)
          return DateTime(p2, p1, p0);
        }
      }
    }
    return null;
  }

  Future<void> refreshData({String? profileId}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    if (profileId != null) {
      _lastProfileId = profileId;
    }
    
    try {
      // Step 1: Workers
      try {
        _workers = await _service.getAllWorkers();
        debugPrint('Fetched ${_workers.length} workers.');
      } catch (e) { 
        debugPrint('Error fetching workers: $e'); 
        _lastError = e.toString();
      }

      // Step 2: Transactions
      try {
        final txs = await _service.getAllTransactions();
        txs.sort((a, b) {
          try {
            final dateA = parseDate(a.date) ?? DateTime(1900);
            final dateB = parseDate(b.date) ?? DateTime(1900);
            final cmp = dateB.compareTo(dateA);
            if (cmp != 0) return cmp;
            
            // Jika tanggal sama, urutkan berdasarkan ID (timestamp input) terbaru di atas
            return b.id.compareTo(a.id);
          } catch (e) {
            return 0;
          }
        });
        _transactions = txs;
        debugPrint('Fetched ${_transactions.length} transactions.');
      } catch (e) { 
        debugPrint('Error fetching transactions: $e'); 
        _lastError = e.toString();
      }

      // Step 3: Attendance & Adjustments
      try {
        _attendance = await _service.getAllAttendance();
        _adjustments = await _service.getAllAdjustments();
        debugPrint('Fetched ${_attendance.length} attendance records.');
        debugPrint('Fetched ${_adjustments.length} adjustments.');
      } catch (e) { 
        debugPrint('Error fetching attendance: $e'); 
        _lastError = e.toString();
      }

      // Step 4: Kasbon
      try {
        _privateKasbon = await _service.getAllPrivateKasbon();
        _globalKasbon = await _service.getAllGlobalKasbon();
        debugPrint('Fetched ${_privateKasbon.length} private kasbon entries.');
        debugPrint('Fetched ${_globalKasbon.length} global kasbon entries.');
      } catch (e) { 
        debugPrint('Error fetching kasbon: $e'); 
        _lastError = e.toString();
      }

      // Step 5: Profile
      if (_lastProfileId != null) {
        try {
          _userProfile = await _service.getUserProfile(_lastProfileId!);
          debugPrint('Profile loaded: ${_userProfile?.name}');
        } catch (e) {
          debugPrint('Error loading profile: $e');
        }
      } 
      
      if (_userProfile == null) {
        // Fallback for initial load if no profileId provided yet
        _userProfile = UserProfile(
          id: 'admin',
          name: 'Aidan Suhendy',
          status: 'Manager',
          address: 'White Kost 35',
          contact: '0851 1135 1735',
        );
      }

      debugPrint('Sync completed. Total Transactions: ${_transactions.length}');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('General error in refreshData: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _userProfile = null;
    _lastProfileId = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async { _isSyncing=true; _lastError=null; notifyListeners(); try{await action();}catch(e){_lastError=e.toString();debugPrint('operation: $e');}finally{_isSyncing=false;notifyListeners();} }
  Future<void> addTransaction(Transaction t)=>_run(() async{await _service.upsertTransaction(t);await refreshData();});
  Future<void> updateTransaction(Transaction t)=>_run(() async{await _service.upsertTransaction(t);await refreshData();});
  Future<void> deleteTransaction(String id)=>_run(() async{await _service.deleteTransaction(id);await refreshData();});

  Future<void> addWorker(Worker w)=>_run(() async{await _service.upsertWorker(w);await refreshData();});
  Future<void> updateWorker(Worker w)=>_run(() async{await _service.upsertWorker(w);await refreshData();});
  Future<void> removeWorker(String id)=>_run(() async{await _service.deleteWorker(id);await refreshData();});

  Future<void> reorderWorker(String workerId, bool moveUp) async {
    final list = _workers.where((w) => w.isActive).toList();
    final index = list.indexWhere((w) => w.id == workerId);
    if (index == -1) return;

    if (moveUp && index > 0) {
      await _performSwap(list[index], list[index - 1]);
    } else if (!moveUp && index < list.length - 1) {
      await _performSwap(list[index], list[index + 1]);
    }
  }

  Future<void> _performSwap(Worker active, Worker neighbor) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final idx1 = active.orderIndex;
      final idx2 = neighbor.orderIndex;
      
      if (idx1 == idx2) {
        final allActive = _workers.where((w) => w.isActive).toList();
        for (int i = 0; i < allActive.length; i++) {
          final w = allActive[i];
          int finalIdx = i;
          if (w.id == active.id) finalIdx = allActive.indexOf(neighbor);
          else if (w.id == neighbor.id) finalIdx = allActive.indexOf(active);
          await _service.upsertWorker(Worker(id: w.id, name: w.name, role: w.role, baseWage: w.baseWage, isActive: w.isActive, orderIndex: finalIdx));
        }
      } else {
        await _service.upsertWorker(Worker(id: active.id, name: active.name, role: active.role, baseWage: active.baseWage, isActive: active.isActive, orderIndex: idx2));
        await _service.upsertWorker(Worker(id: neighbor.id, name: neighbor.name, role: neighbor.role, baseWage: neighbor.baseWage, isActive: neighbor.isActive, orderIndex: idx1));
      }
      await refreshData();
    } catch (e) {
      debugPrint('Reorder error: $e');
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updateAttendance(String workerId,DateTime date,AttendanceStatus status)=>_run(() async{final ds=DateFormat('yyyy-MM-dd').format(date);await _service.upsertAttendance(AttendanceRecord(id:'${workerId}_$ds',workerId:workerId,date:ds,status:status));await refreshData();});
  Future<void> updateOvertime(String workerId,double amount)=>_run(() async{final id='${workerId}_$weekStartString';final old=_adjustments.where((a)=>a.workerId==workerId).firstOrNull;await _service.upsertAdjustment(WeeklyAdjustment(id:id,workerId:workerId,weekStartDate:weekStartString,manualOvertime:amount,privateKasbon:old?.privateKasbon??0));await refreshData();});
  Future<void> updateWeeklyDebtPayment(String workerId,double amount,{DateTime? date})=>_run(() async{final id='${workerId}_$weekStartString';final old=_adjustments.where((a)=>a.workerId==workerId).firstOrNull;await _service.upsertAdjustment(WeeklyAdjustment(id:id,workerId:workerId,weekStartDate:weekStartString,manualOvertime:old?.manualOvertime??0,privateKasbon:amount));await _service.upsertPrivateKasbon(PrivateKasbonEntry(id:'auto_${workerId}_$weekStartString',workerId:workerId,date:date != null ? DateFormat('yyyy-MM-dd').format(date) : weekEndString,description:'Bayar hutang pribadi',paymentAmount:amount,note:amount==0?'Tidak bayar':''));await refreshData();});

  Future<void> addGlobalKasbon({required DateTime date,required double amount,String description='Kasbon uang makan',bool createTransaction=true})=>_run(() async{final ds=DateFormat('yyyy-MM-dd').format(date);await _service.upsertGlobalKasbon(GlobalKasbonEntry(id:'global_${DateTime.now().microsecondsSinceEpoch}',weekStartDate:weekStartString,date:ds,description:description,amount:amount));if(createTransaction){await _service.upsertTransaction(Transaction(id:'p4_gd_kasbon_${DateTime.now().microsecondsSinceEpoch}',periodId:'p4',title:description,amount:amount,date:DateFormat('dd/MM/yyyy').format(date),category:'Gondes',note:'Kasbon Global'));}await refreshData();});
  Future<void> updateGlobalKasbon(GlobalKasbonEntry e)=>_run(() async{await _service.upsertGlobalKasbon(e);await refreshData();});
  Future<void> deleteGlobalKasbon(String id)=>_run(() async{await _service.deleteGlobalKasbon(id);await refreshData();});
  Future<void> addPrivateKasbon(PrivateKasbonEntry e)=>_run(() async{await _service.upsertPrivateKasbon(e);await refreshData();});
  Future<void> updatePrivateKasbon(PrivateKasbonEntry e)=>_run(() async{await _service.upsertPrivateKasbon(e);await refreshData();});
  Future<void> deletePrivateKasbon(String id)=>_run(() async{await _service.deletePrivateKasbon(id);await refreshData();});

  Future<void> updateProfilePhoto(Uint8List bytes) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final url = await _service.uploadProfilePhoto(bytes);
      if (url != null && _userProfile != null) {
        _userProfile = _userProfile!.copyWith(photoUrl: url);
        await _service.upsertUserProfile(_userProfile!);
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    _isSyncing = true;
    notifyListeners();
    try {
      await _service.upsertUserProfile(profile);
      _userProfile = profile;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> markAsPaid(double amount,DateTime payoutDate)=>_run(() async{await _service.upsertTransaction(Transaction(id:'p4_gd_paid_${DateTime.now().millisecondsSinceEpoch}',periodId:activePeriod?.id??'p4',title:'Upah Gondes',amount:amount,date:DateFormat('dd/MM/yyyy').format(payoutDate),category:'Gondes',note:'Gajian minggu $weekStartString s/d $weekEndString'));await _service.resetWeekData(weekStartString,weekEndString);await refreshData();});
  void nextWeek(){_currentWeekStart=_currentWeekStart.add(const Duration(days:7));refreshData();notifyListeners();}
  void prevWeek(){_currentWeekStart=_currentWeekStart.subtract(const Duration(days:7));refreshData();notifyListeners();}
  void thisWeek(){_currentWeekStart=_sunday(DateTime.now());refreshData();notifyListeners();}
}
