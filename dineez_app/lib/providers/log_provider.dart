import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// Log level enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

// Log entry class
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;
  final dynamic data;

  LogEntry({
    required this.level,
    required this.message,
    this.source,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert log entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
      'message': message,
      'source': source,
      'data': data?.toString(),
    };
  }

  // Convert log entry to string format
  @override
  String toString() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final formattedDate = dateFormat.format(timestamp);
    final levelStr = level.toString().split('.').last.toUpperCase();
    final sourceStr = source != null ? '[$source]' : '';
    return '[$formattedDate] $levelStr $sourceStr: $message${data != null ? ' - Data: $data' : ''}';
  }
}

// Log state class
class LogState {
  final List<LogEntry> logs;
  final int maxInMemoryLogs;
  final bool isLoading;
  final String? errorMessage;

  const LogState({
    this.logs = const [],
    this.maxInMemoryLogs = 1000,
    this.isLoading = false,
    this.errorMessage,
  });

  LogState copyWith({
    List<LogEntry>? logs,
    int? maxInMemoryLogs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      maxInMemoryLogs: maxInMemoryLogs ?? this.maxInMemoryLogs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Get logs for a specific level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return logs.where((log) => log.level == level).toList();
  }

  // Get logs for a specific source
  List<LogEntry> getLogsBySource(String source) {
    return logs.where((log) => log.source == source).toList();
  }
}

// Log notifier class
class LogNotifier extends StateNotifier<LogState> {
  LogNotifier() : super(const LogState()) {
    _initLogDirectory();
  }

  File? _logFile;
  DateTime _currentLogDate = DateTime.now();

  // Initialize log directory
  Future<void> _initLogDirectory() async {
    try {
      state = state.copyWith(isLoading: true);
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      _setupLogFile();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize log directory: $e',
      );
    }
  }

  // Setup log file with current date
  Future<void> _setupLogFile() async {
    _currentLogDate = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(_currentLogDate);
    
    final appDocDir = await getApplicationDocumentsDirectory();
    final logFilePath = '${appDocDir.path}/logs/dineez_$formattedDate.log';
    _logFile = File(logFilePath);
    
    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }
  }

  // Check if log date needs to be rolled over
  Future<void> _checkLogDateRollover() async {
    final now = DateTime.now();
    if (now.day != _currentLogDate.day ||
        now.month != _currentLogDate.month ||
        now.year != _currentLogDate.year) {
      await _setupLogFile();
    }
  }

  // Add log entry
  Future<void> log(
    LogLevel level,
    String message, {
    String? source,
    dynamic data,
  }) async {
    final logEntry = LogEntry(
      level: level,
      message: message,
      source: source,
      data: data,
    );

    // Add to in-memory logs
    final updatedLogs = [...state.logs, logEntry];
    
    // Trim if exceeded max logs
    final trimmedLogs = updatedLogs.length > state.maxInMemoryLogs
        ? updatedLogs.sublist(updatedLogs.length - state.maxInMemoryLogs)
        : updatedLogs;
    
    state = state.copyWith(logs: trimmedLogs);

    // Write to log file
    await _writeToLogFile(logEntry);
  }

  // Write log entry to file
  Future<void> _writeToLogFile(LogEntry logEntry) async {
    try {
      await _checkLogDateRollover();
      if (_logFile != null) {
        await _logFile!.writeAsString(
          '${logEntry.toString()}\n',
          mode: FileMode.append,
        );
      }
    } catch (e) {
      // Don't update state here to avoid recursive logs
      print('Failed to write to log file: $e');
    }
  }

  // Clear logs
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  // Get logs for a specific level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return state.getLogsByLevel(level);
  }

  // Get logs for a specific source
  List<LogEntry> getLogsBySource(String source) {
    return state.getLogsBySource(source);
  }

  // Export logs to a specific file
  Future<String?> exportLogs() async {
    try {
      state = state.copyWith(isLoading: true);
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final formattedDate = dateFormat.format(now);
      
      final appDocDir = await getApplicationDocumentsDirectory();
      final exportFilePath = '${appDocDir.path}/logs/export_$formattedDate.log';
      final exportFile = File(exportFilePath);
      
      if (!await exportFile.exists()) {
        await exportFile.create(recursive: true);
      }
      
      for (final log in state.logs) {
        await exportFile.writeAsString(
          '${log.toString()}\n',
          mode: FileMode.append,
        );
      }
      
      state = state.copyWith(isLoading: false);
      return exportFilePath;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to export logs: $e',
      );
      return null;
    }
  }
}

// Log provider
final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier();
});

// Convenience log methods
final logDebugProvider = Provider<Function(String, {String? source, dynamic data})>((ref) {
  return (String message, {String? source, dynamic data}) {
    ref.read(logProvider.notifier).log(LogLevel.debug, message, source: source, data: data);
  };
});

final logInfoProvider = Provider<Function(String, {String? source, dynamic data})>((ref) {
  return (String message, {String? source, dynamic data}) {
    ref.read(logProvider.notifier).log(LogLevel.info, message, source: source, data: data);
  };
});

final logWarningProvider = Provider<Function(String, {String? source, dynamic data})>((ref) {
  return (String message, {String? source, dynamic data}) {
    ref.read(logProvider.notifier).log(LogLevel.warning, message, source: source, data: data);
  };
});

final logErrorProvider = Provider<Function(String, {String? source, dynamic data})>((ref) {
  return (String message, {String? source, dynamic data}) {
    ref.read(logProvider.notifier).log(LogLevel.error, message, source: source, data: data);
  };
});

final logCriticalProvider = Provider<Function(String, {String? source, dynamic data})>((ref) {
  return (String message, {String? source, dynamic data}) {
    ref.read(logProvider.notifier).log(LogLevel.critical, message, source: source, data: data);
  };
}); 