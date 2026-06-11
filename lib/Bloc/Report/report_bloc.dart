import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/data/repositories/report/report_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class ReportTodayEvent {}

class ReportTodayList extends ReportTodayEvent {
  String fromDate;
  String toDate;
  String tableId;
  String waiterId;
  String operatorId;
  ReportTodayList(
      this.fromDate, this.toDate, this.tableId, this.waiterId, this.operatorId);
}

class TableDine extends ReportTodayEvent {}

class WaiterDine extends ReportTodayEvent {}

class UserDetails extends ReportTodayEvent {}

class FetchCompanyCurrent extends ReportTodayEvent {}

class FetchLocationDetails extends ReportTodayEvent {}

class ReportTodayBloc extends Bloc<ReportTodayEvent, dynamic> {
  final ReportRepository _reportRepository;
  final LogService _logService;
  static const String tag = 'ReportTodayBloc';

  ReportTodayBloc({
    ReportRepository? reportRepository,
    LogService? logService,
  })  : _reportRepository = reportRepository ?? injector<ReportRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<ReportTodayList>(_onReportTodayList);
    on<TableDine>(_onTableDine);
    on<WaiterDine>(_onWaiterDine);
    on<UserDetails>(_onUserDetails);
    on<FetchCompanyCurrent>(_onFetchCompanyCurrent);
    on<FetchLocationDetails>(_onFetchLocationDetails);
  }

  Future<void> _onReportTodayList(
      ReportTodayList event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getReportToday(
          event.fromDate, event.toDate, event.tableId, event.waiterId, event.operatorId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag ReportTodayList error", e, s);
      emit(e);
    }
  }

  Future<void> _onTableDine(TableDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getTable();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag TableDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onWaiterDine(WaiterDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getWaiter();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag WaiterDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onUserDetails(UserDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getUserDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag UserDetails error", e, s);
      emit(e);
    }
  }

  Future<void> _onFetchCompanyCurrent(
      FetchCompanyCurrent event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getCompanyCurrent();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FetchCompanyCurrent error", e, s);
      emit(e);
    }
  }

  Future<void> _onFetchLocationDetails(
      FetchLocationDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _reportRepository.getLocationDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FetchLocationDetails error", e, s);
      emit(e);
    }
  }
}
