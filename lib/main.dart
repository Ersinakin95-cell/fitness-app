import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const StepRewardApp());
}

class StepRewardApp extends StatelessWidget {
  const StepRewardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Reward',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _coins = 150; // Начальный баланс монет для теста
  int _steps = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        steps: _steps,
        coins: _coins,
        onStepsUpdated: (steps) {
          setState(() {
            _steps = steps;
            _coins = steps ~/ 100;
          });
        },
        onBonusEarned: (bonus) {
          setState(() {
            _coins += bonus;
          });
        },
      ),
      const LeaderboardScreen(),
      ShopScreen(
        coins: _coins,
        onRedeem: (cost) {
          if (_coins >= cost) {
            setState(() {
              _coins -= cost;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сыйлық сәтті алынды!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Упай жеткіліксіз!')),
            );
          }
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: 'Басты'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Рейтинг'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Дүкен'),
        ],
      ),
    );
  }
}

// ------------------- ГЛАВНЫЙ ЭКРАН -------------------
class HomeScreen extends StatefulWidget {
  final int steps;
  final int coins;
  final Function(int) onStepsUpdated;
  final Function(int) onBonusEarned;

  const HomeScreen({
    super.key,
    required this.steps,
    required this.coins,
    required this.onStepsUpdated,
    required this.onBonusEarned,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _loadBannerAd();
    _loadRewardedAd();
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      Pedometer.stepCountStream.listen((event) {
        widget.onStepsUpdated(event.steps);
      });
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedLoaded = true;
          });
        },
        onAdFailedToLoad: (_) => _isRewardedLoaded = false,
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null && _isRewardedLoaded) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        widget.onBonusEarned(50);
      });
      _rewardedAd = null;
      _isRewardedLoaded = false;
      _loadRewardedAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Жаттығу мен Қадам'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk, size: 80, color: Colors.green),
                  const SizedBox(height: 15),
                  Text('Бүгінгі қадамдар:', style: Theme.of(context).textTheme.titleMedium),
                  Text('${widget.steps}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 30),
                        const SizedBox(width: 10),
                        Text('Ұпайлар: ${widget.coins}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isRewardedLoaded ? _showRewardedAd : null,
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Видео көріп, +50 ұпай ал!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerLoaded)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

// ------------------- ЭКРАН РЕЙТИНГА -------------------
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> topUsers = [
      {'name': 'Айдос К.', 'steps': 14200, 'rank': 1},
      {'name': 'Аружан С.', 'steps': 12800, 'rank': 2},
      {'name': 'Ерсұлы О.', 'steps': 10500, 'rank': 3},
      {'name': 'Нұрбек Т.', 'steps': 8900, 'rank': 4},
      {'name': 'Динара М.', 'steps': 7400, 'rank': 5},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Үздік белсенділер'), centerTitle: true),
      body: ListView.builder(
        itemCount: topUsers.length,
        itemBuilder: (context, index) {
          final user = topUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.amber : Colors.grey.shade300,
              child: Text('#${user['rank']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user['steps']} қадам'),
            trailing: const Icon(Icons.emoji_events, color: Colors.amber),
          );
        },
      ),
    );
  }
}

// ------------------- ЭКРАН МАГАЗИНА -------------------
class ShopScreen extends StatelessWidget {
  final int coins;
  final Function(int) onRedeem;

  const ShopScreen({super.key, required this.coins, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': '10% жеңілдік промокоды', 'cost': 100, 'icon': Icons.local_offer},
      {'title': 'Премиум статус (1 күн)', 'cost': 300, 'icon': Icons.star},
      {'title': 'Фитнес-программа купоны', 'cost': 500, 'icon': Icons.fitness_center},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Дүкен (Баланс: $coins 🪙)'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(item['icon'], size: 40, color: Colors.green),
              title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['cost']} ұпай'),
              trailing: ElevatedButton(
                onPressed: coins >= item['cost'] ? () => onRedeem(item['cost']) : null,
                child: const Text('Алу'),
              ),
            ),
          );
        },
      ),
    );
  }
}
