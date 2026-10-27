import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/purchase_service.dart';
import '../../core/theme/app_theme.dart';
import '../home_shell/home_shell_screen.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final bool isFromOnboarding;
  const PaywallScreen({super.key, this.isFromOnboarding = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPlan = 'yearly';

  void _dismiss() {
    if (widget.isFromOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShellScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handlePurchase() async {
    final success = await ref
        .read(purchaseProvider.notifier)
        .purchasePlan(_selectedPlan);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم تفعيل اشتراك DADA Pro بنجاح! استمتع بكل المزايا.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      _dismiss();
    }
  }

  Future<void> _handleRestore() async {
    final restored =
        await ref.read(purchaseProvider.notifier).restorePurchases();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored
              ? '✅ تم استعادة اشتراك DADA Pro بنجاح.'
              : 'ℹ️ لم يتم العثور على اشتراكات سابقة نشطة.'),
          backgroundColor:
              restored ? AppTheme.accentColor : Colors.grey.shade800,
        ),
      );
      if (restored) _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseState = ref.watch(purchaseProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Pro Crown / Badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF9F43)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9F43).withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  const Text(
                    'Unlock DADA Pro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ترجمة غير محدودة بالذكاء الاصطناعي على جهازك وبأعلى دقة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature Checklist
                  _buildFeatureRow(
                    icon: Icons.offline_bolt_rounded,
                    title: 'حزم اللغات الـ 19 دون إنترنت بالكامل',
                    subtitle: '100% Offline Neural Machine Translation',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.camera_enhance_rounded,
                    title: 'ترجمة الكاميرا الحية واستبدال النصوص AR',
                    subtitle: 'Real-time Camera Text Overlays',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'محادثة حية ثنائية شاشة منقسمة غير محدودة',
                    subtitle: 'Face-to-Face Dual Mic Live Speech',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.school_rounded,
                    title: 'سيناريوهات مدرب المحادثة الذكي James',
                    subtitle: 'All Pronunciation & Travel Scenarios',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.widgets_rounded,
                    title: 'ويدجت الشاشة الرئيسية ولوحة مفاتيح iOS',
                    subtitle: 'DADA WidgetKit & Keyboard Extension Sync',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // Pricing Options
                  // Yearly Option (Best Value)
                  _buildPlanOption(
                    id: 'yearly',
                    title: 'الباقة السنوية (Yearly)',
                    price: '\$39.99 / سنة',
                    weeklyRate: '\$0.77 / أسبوع فقط',
                    badgeText: 'BEST VALUE - خصم 84%',
                    badgeColor: const Color(0xFFFF9F43),
                    trialText: 'يشمل 3 أيام تجربة مجانية مجاناً',
                    isSelected: _selectedPlan == 'yearly',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedPlan = 'yearly'),
                  ),
                  const SizedBox(height: 14),

                  // Weekly Option (Most Popular)
                  _buildPlanOption(
                    id: 'weekly',
                    title: 'الباقة الأسبوعية (Weekly)',
                    price: '\$4.99 / أسبوع',
                    weeklyRate: 'مرونة الاشتراك أسبوعاً بأسبوع',
                    badgeText: 'MOST POPULAR',
                    badgeColor: AppTheme.primaryColor,
                    trialText: 'تجديد تلقائي - يمكنك الإلغاء في أي وقت',
                    isSelected: _selectedPlan == 'weekly',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedPlan = 'weekly'),
                  ),
                  const SizedBox(height: 28),

                  // CTA Button
                  ElevatedButton(
                    onPressed:
                        purchaseState.isLoading ? null : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: purchaseState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _selectedPlan == 'yearly'
                                ? 'ابدأ تجربتك المجانية 3 أيام الآن'
                                : 'تفعيل اشتراك DADA Pro',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: purchaseState.isLoading
                            ? null
                            : _handleRestore,
                        child: Text(
                          'استعادة المشتريات (Restore)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    'يتجدد الاشتراك تلقائياً ما لم يتم الإلغاء قبل 24 ساعة من نهاية الفترة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Top Close Button
            Positioned(
              top: 12,
              left: 16,
              child: IconButton(
                onPressed: _dismiss,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String id,
    required String title,
    required String price,
    required String weeklyRate,
    required String badgeText,
    required Color badgeColor,
    required String trialText,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.06)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white30 : Colors.black26),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weeklyRate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  trialText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
