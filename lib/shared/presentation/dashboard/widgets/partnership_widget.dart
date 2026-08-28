import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class PartnershipWidget extends StatefulWidget {
  final VoidCallback onViewAllPressed;

  const PartnershipWidget({
    Key? key,
    required this.onViewAllPressed,
  }) : super(key: key);

  @override
  State<PartnershipWidget> createState() => _PartnershipWidgetState();
}

class _PartnershipWidgetState extends State<PartnershipWidget> {
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _secondary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await SupabaseService.instance.client
          .from('partners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final all = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _featured  = all.where((p) => p['is_featured'] == true).toList();
          _secondary = all.where((p) => p['is_featured'] != true).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.dividerGray;
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyCoupon(BuildContext context, String coupon) {
    Clipboard.setData(ClipboardData(text: coupon));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).dashboard_partner_coupon_copied(coupon)),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto carrega, mostra placeholder visível (nunca tela vazia/parada).
    if (_isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.all(4.w),
        height: 14.h,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray, width: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: AppTheme.accentGold, strokeWidth: 2),
          ),
        ),
      );
    }

    // D9 — exceção única: só some de vez quando REALMENTE não há parceiro
    // ativo (não durante o carregamento). O widget permanece no código e
    // volta sozinho quando houver dado.
    if (_featured.isEmpty && _secondary.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'handshake',
                  color: AppTheme.accentGold,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                AppLocalizations.of(context).dashboard_partners_title,
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_featured.isNotEmpty) ...[
            SizedBox(height: 3.h),
            _buildFeaturedCard(context, _featured.first),
          ],
          if (_secondary.isNotEmpty) ...[
            SizedBox(height: 2.h),
            _buildCarousel(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Map<String, dynamic> partner) {
    final borderColor = _parseColor(partner['border_color'] as String?);
    final linkUrl = partner['link_url'] as String?;
    final coupon = partner['coupon_code'] as String?;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _launchUrl(linkUrl),
            child: Container(
              height: 8.h,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: CustomImageWidget(
                  imageUrl: partner['image_url'] as String,
                  height: 6.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            partner['tagline'] as String? ?? '',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: linkUrl != null ? () => _launchUrl(linkUrl) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.primaryBlack,
                    padding: EdgeInsets.symmetric(vertical: 2.5.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).dashboard_partner_view_offer_btn,
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (coupon != null) ...[
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _copyCoupon(context, coupon),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGold,
                      side: BorderSide(color: AppTheme.accentGold, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 2.5.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).dashboard_partner_copy_coupon_btn,
                      style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    return SizedBox(
      height: 14.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _secondary.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          if (index == _secondary.length) return _buildViewAllCard();
          return _buildSecondaryCard(context, _secondary[index]);
        },
      ),
    );
  }

  Widget _buildSecondaryCard(BuildContext context, Map<String, dynamic> partner) {
    final borderColor = _parseColor(partner['border_color'] as String?);
    final linkUrl = partner['link_url'] as String?;

    return GestureDetector(
      onTap: () => _launchUrl(linkUrl),
      child: Container(
        width: 28.w,
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: CustomImageWidget(
                    imageUrl: partner['image_url'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              partner['name'] as String? ?? '',
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: widget.onViewAllPressed,
      child: Container(
        width: 28.w,
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded, color: AppTheme.accentGold, size: 6.w),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context).dashboard_partners_view_all_btn,
              style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
