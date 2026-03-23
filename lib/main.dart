import 'package:flutter/material.dart';
import 'package:rent_management/data_sources/shared_prefs_lease_local_data_source.dart';
import 'package:rent_management/repositories/in_memory_lease_repository.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/screens/home_screen.dart';
import 'package:rent_management/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RentManagementApp());
}

class RentManagementApp extends StatelessWidget {
  const RentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '임대 관리',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      ),
      home: const AppBootstrapScreen(),
    );
  }
}

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  late final Future<LeaseRepository> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _loadRepository();
  }

  Future<LeaseRepository> _loadRepository() async {
    try {
      await NotificationService.instance.initialize().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {}

    final localDataSource = await SharedPrefsLeaseLocalDataSource.create();
    return InMemoryLeaseRepository.create(
      localDataSource: localDataSource,
      fallbackSampleLeases: InMemoryLeaseRepository.buildSampleLeases(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaseRepository>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '앱을 시작하지 못했습니다.\n${snapshot.error ?? '알 수 없는 오류'}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return HomeScreen(repository: snapshot.data!);
      },
    );
  }
}
