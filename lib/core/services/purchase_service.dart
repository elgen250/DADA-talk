import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget_sync_service.dart';

class PurchaseState {
  final bool isPro;
  final bool isLoading;
  final String? activePlan; // 'yearly', 'weekly', null

  const PurchaseState({
    this.isPro = false,
    this.isLoading = false,
    this.activePlan,
  });

  PurchaseState copyWith({
    bool? isPro,
    bool? isLoading,
    String? activePlan,
  }) {
    return PurchaseState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      activePlan: activePlan ?? this.activePlan,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier() : super(const PurchaseState()) {
    _loadProStatus();
  }

  static const String _proKey = 'vava_is_pro_user';
  static const String _planKey = 'vava_active_plan';

  Future<void> _loadProStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPro = prefs.getBool(_proKey) ?? false;
      final plan = prefs.getString(_planKey);
      state = state.copyWith(isPro: isPro, activePlan: plan);
    } catch (_) {}
  }

  Future<bool> purchasePlan(String plan) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate transaction

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, true);
    await prefs.setString(_planKey, plan);

    await WidgetSyncService.instance.syncProStatus(true);

    state = state.copyWith(
      isPro: true,
      isLoading: false,
      activePlan: plan,
    );
    return true;
  }

  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 700));

    final prefs = await SharedPreferences.getInstance();
    final wasPro = prefs.getBool(_proKey) ?? false;
    final plan = prefs.getString(_planKey) ?? (wasPro ? 'yearly' : null);

    state = state.copyWith(
      isPro: wasPro,
      isLoading: false,
      activePlan: plan,
    );
    return wasPro;
  }
}

final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  return PurchaseNotifier();
});
