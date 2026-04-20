import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/dashboard_controller.dart';
import 'home_feature.dart';

class DashboardTab extends StatefulWidget {
  final List<HomeFeature> features;
  final ValueChanged<HomeFeature> onTapFeature;
  final String userName;

  const DashboardTab({
    super.key,
    required this.features,
    required this.onTapFeature,
    required this.userName,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final DashboardController _controller;
  final PageController _highlightController = PageController(
    viewportFraction: 0.92,
  );
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
    _startHighlightAutoSlide();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _highlightController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _startHighlightAutoSlide() {
    _highlightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_highlightController.hasClients) return;
      final next =
          (_controller.highlightIndex + 1) %
          DashboardController.highlightItems.length;
      _highlightController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      _controller.setHighlightIndex(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoneNow = _controller.nowInZone(_controller.activeZone);
    final nextPrayer = _controller.nextPrayer(zoneNow);

    return RefreshIndicator(
      onRefresh: _controller.refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _heroCard(nextPrayer, zoneNow),
          const SizedBox(height: 16),
          _sectionHeader(
            'Layanan Utama',
            'Akses fitur harian dalam satu sentuhan',
          ),
          const SizedBox(height: 10),
          _featureMenuSection(widget.features),
          const SizedBox(height: 16),
          _sectionHeader(
            'Highlight Pilihan',
            'Geser untuk melihat rekomendasi',
          ),
          const SizedBox(height: 10),
          _highlightSlider(),
          const SizedBox(height: 16),
          _sectionHeader(
            'Doa Hari Ini',
            'Temani aktivitasmu dengan doa terbaik',
          ),
          const SizedBox(height: 10),
          _randomDoaCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, DateTime) nextPrayer, DateTime zoneNow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4F73), Color(0xFF116E86), Color(0xFF34A39B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5E7D).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nikmati Perjalanan Ibadahmu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _controller.formatDateCompact(zoneNow),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_controller.formatHmWithDot(zoneNow)} ${_controller.activeZone.trim()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _controller.formatRegionLine(_controller.activeRegion),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_controller.loadingPrayerSetting)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Sinkronisasi jadwal dari Waktu & Sholat ID...',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrayerBubble(
                  title: 'Sedang Berlangsung',
                  prayer: _controller.currentPrayer(zoneNow),
                  value: _controller.formatHm(
                    _controller.toDate(
                      zoneNow,
                      _controller.prayerTimes[_controller.currentPrayer(
                        zoneNow,
                      )]!,
                    ),
                  ),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrayerBubble(
                  title: 'Berikutnya',
                  prayer: nextPrayer.$1,
                  value: 'in ${_controller.countdown(zoneNow, nextPrayer.$2)}',
                  icon: Icons.nights_stay_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF647377),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureMiniGrid(List<HomeFeature> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        mainAxisExtent: 102,
      ),
      itemBuilder: (context, index) {
        final feature = items[index];
        return _FeatureMiniCard(
          feature: feature,
          onTap: () => widget.onTapFeature(feature),
        );
      },
    );
  }

  Widget _featureMenuSection(List<HomeFeature> allItems) {
    final topItems = _controller.topFeatures(allItems);
    final moreItems = _controller.moreFeatures(allItems);

    return Column(
      children: [
        _featureMiniGrid(topItems),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _controller.showMoreFeatures && moreItems.isNotEmpty
              ? Column(
                  children: [
                    const SizedBox(height: 12),
                    _featureMiniGrid(moreItems),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        if (moreItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _controller.toggleMoreFeatures,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF24659B),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              icon: Icon(
                _controller.showMoreFeatures
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(_controller.showMoreFeatures ? 'Tutup' : 'Lainnya'),
            ),
          ),
      ],
    );
  }

  Widget _highlightSlider() {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _highlightController,
            itemCount: DashboardController.highlightItems.length,
            onPageChanged: _controller.setHighlightIndex,
            itemBuilder: (context, index) {
              final item = DashboardController.highlightItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.colors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Icon(item.icon, color: Colors.white, size: 23),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(DashboardController.highlightItems.length, (
            index,
          ) {
            final active = index == _controller.highlightIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: active
                    ? const Color(0xFF1B6D94)
                    : const Color(0xFFCAD8E0),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _randomDoaCard() {
    return FutureBuilder(
      future: _controller.doaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _controller.randomDoa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 12),
                Text('Memuat doa random...'),
              ],
            ),
          );
        }

        if (snapshot.hasError && _controller.randomDoa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Gagal memuat doa random. Tarik ke bawah untuk mencoba lagi.',
            ),
          );
        }

        final doa = _controller.randomDoa;
        if (doa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('Data doa belum tersedia.'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE1ECEA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF082B2A).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFDDF1EF),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF0A6C5D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Doa Random Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.pickRandomDoa,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh doa random',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                doa.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                doa.group,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                doa.arabic,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(doa.translation, style: const TextStyle(height: 1.4)),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerBubble extends StatelessWidget {
  final String title;
  final String prayer;
  final String value;
  final IconData icon;

  const _PrayerBubble({
    required this.title,
    required this.prayer,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  prayer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final HomeFeature feature;
  final VoidCallback onTap;

  const _FeatureMiniCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: feature.color.withValues(alpha: 0.75),
                  width: 1.2,
                ),
              ),
              child: Icon(feature.icon, color: feature.color, size: 21),
            ),
            const SizedBox(height: 9),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.16,
                color: Color(0xFF24344A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
