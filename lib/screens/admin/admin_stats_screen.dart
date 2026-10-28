import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/category_query.dart';
import '../../models/customer_query.dart';
import '../../models/manufacturer_query.dart';
import '../../models/material_query.dart';
import '../../models/page_result.dart';
import '../../models/product_query.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/repositories.dart';
import '../../state/load_status.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/state_views.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  final _values = <String, int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final products =
          context.read<ProductRepository>().find(const ProductQuery(size: 1));
      final categories =
          context.read<CategoryRepository>().find(const CategoryQuery(size: 1));
      final manufacturers = context
          .read<ManufacturerRepository>()
          .find(const ManufacturerQuery(size: 1));
      final materials =
          context.read<MaterialRepository>().find(const MaterialQuery(size: 1));
      final customers =
          context.read<CustomerRepository>().find(const CustomerQuery(size: 1));
      final users = context.read<UserRepository>().find(size: 1);

      final results = await Future.wait<Object>([
        products,
        categories,
        manufacturers,
        materials,
        customers,
        users,
      ]);
      if (!mounted) return;
      setState(() {
        _values['Товары'] = (results[0] as PageResult<dynamic>).total;
        _values['Категории'] = (results[1] as PageResult<dynamic>).total;
        _values['Производители'] = (results[2] as PageResult<dynamic>).total;
        _values['Материалы'] = (results[3] as PageResult<dynamic>).total;
        _values['Покупатели'] = (results[4] as PageResult<dynamic>).total;
        _values['Пользователи'] = (results[5] as PageResult<dynamic>).total;
        _status = LoadStatus.success;
      });
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Сервер отклонил запрос: ${e.message} (код 403)';
        _status = LoadStatus.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить статистику: $e';
        _status = LoadStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Статистика',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: _error ?? 'Ошибка загрузки',
          onRetry: _load,
        );
      case LoadStatus.success:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сводка по магазину',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Экран доступен только администратору.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 620
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final entry in _values.entries)
                        SizedBox(
                          width: width,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${entry.value}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
    }
  }
}
