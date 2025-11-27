import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../data/services/admob_service.dart';
import '../../../core/utils/debug_logger.dart';
import 'ad_placeholder_widget.dart';

class AdmobBannerWidget extends StatefulWidget {
  final AdSize adSize;
  final double? height;
  final EdgeInsets? margin;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;
  final bool showPlaceholder;

  const AdmobBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.height,
    this.margin,
    this.onAdLoaded,
    this.onAdFailed,
    this.showPlaceholder = true,
  });

  @override
  State<AdmobBannerWidget> createState() => _AdmobBannerWidgetState();
}

class _AdmobBannerWidgetState extends State<AdmobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = AdmobService().createBannerAd(
        adSize: widget.adSize,
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _loadFailed = false;
            });
            widget.onAdLoaded?.call();
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (mounted) {
            setState(() {
              _loadFailed = true;
              _isAdLoaded = false;
            });
            widget.onAdFailed?.call();
          }
        },
      );

      await _bannerAd?.load();
    } catch (e) {
      DebugLogger.logAdError('Error in banner ad loading', 
        adType: 'BANNER', error: e);
      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed && widget.showPlaceholder) {
      return AdPlaceholderWidget(
        height: widget.height ?? widget.adSize.height.toDouble(),
        margin: widget.margin,
        adType: 'Banner',
      );
    }

    if (!_isAdLoaded || _bannerAd == null) {
      return AdPlaceholderWidget(
        height: widget.height ?? widget.adSize.height.toDouble(),
        margin: widget.margin,
        isLoading: true,
        adType: 'Banner',
      );
    }

    return Container(
      height: widget.height ?? _bannerAd!.size.height.toDouble(),
      margin: widget.margin,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}