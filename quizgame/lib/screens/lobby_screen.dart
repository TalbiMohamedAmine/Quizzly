import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/room_service.dart';
import '../models/room.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomService = RoomService();
  bool _leaving = false;

  // Available categories
  static const List<Map<String, dynamic>> _allCategories = [
    {'name': 'Labobo', 'isVip': false},
    {'name': 'Strange questions', 'isVip': false},
    {'name': 'Chocolate sweets', 'isVip': false},
    {'name': 'General information', 'isVip': false},
    {'name': 'Sciences', 'isVip': false},
    {'name': 'Who is the famous person?', 'isVip': false},
    {'name': 'Arts', 'isVip': false},
    {'name': 'Soccer', 'isVip': false},
    {'name': 'Sports', 'isVip': false},
    {'name': 'Geography', 'isVip': false},
    {'name': 'Information', 'isVip': false},
    {'name': 'Maps', 'isVip': false},
    {'name': 'Kuwait', 'isVip': false},
    {'name': 'Literature', 'isVip': true},
    {'name': 'Date', 'isVip': false},
    {'name': 'Video games', 'isVip': true},
    {'name': 'Cartoon', 'isVip': true},
    {'name': 'TV series', 'isVip': false},
    {'name': 'Films', 'isVip': false},
    {'name': 'Fashion world', 'isVip': false},
    {'name': 'Guinness World Records', 'isVip': false},
    {'name': 'Digital currencies', 'isVip': false},
    {'name': 'Logos of universities', 'isVip': false},
    {'name': 'Technology', 'isVip': false},
    {'name': 'Currency', 'isVip': false},
    {'name': 'Slogans', 'isVip': false},
    {'name': 'Guess the airport', 'isVip': false},
    {'name': 'Products', 'isVip': false},
    {'name': 'Fruits and vegetables', 'isVip': false},
    {'name': 'Proverbs and riddles', 'isVip': false},
    {'name': 'Ramadan Nights', 'isVip': false},
    {'name': 'Restaurants', 'isVip': false},
    {'name': 'Characters', 'isVip': false},
    {'name': 'Restaurant logos', 'isVip': false},
    {'name': 'Cars', 'isVip': false},
    {'name': 'Aviation world', 'isVip': false},
    {'name': 'The kitchen', 'isVip': false},
    {'name': 'Food', 'isVip': false},
    {'name': 'Mathematics', 'isVip': false},
    {'name': 'Plants', 'isVip': false},
    {'name': 'Body science and health', 'isVip': false},
    {'name': 'Astronomy and space', 'isVip': false},
    {'name': 'General medicine', 'isVip': false},
    {'name': 'Math puzzles', 'isVip': false},
    {'name': 'Physics', 'isVip': false},
    {'name': 'Inventors and inventions', 'isVip': false},
  ];

  String get _shareLink => 'https://quizgame.app/join/${widget.roomId}';

  Future<void> _leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _leaving) return;

    setState(() => _leaving = true);

    try {
      await _roomService.removePlayerFromRoom(
        roomId: widget.roomId,
        uid: user.uid,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _leaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave room')),
        );
      }
    }
  }

  Future<void> _shareRoom(String code) async {
    await Share.share(
      'Join my Quiz Game room!\nRoom Code: $code\nLink: $_shareLink',
      subject: 'Join my Quiz Game!',
    );
  }

  void _copyLink(String code) {
    Clipboard.setData(ClipboardData(text: 'Room Code: $code\n$_shareLink'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05396B), // Deep blue background
        appBar: AppBar(
          backgroundColor: const Color(0xFF05396B),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          title: const Text('Lobby', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _leaving ? null : _leaveRoom,
            ),
          ],
        ),
        body: _leaving
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : StreamBuilder<Room>(
                stream: _roomService.watchRoom(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Room no longer exists',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to Menu'),
                          ),
                        ],
                      ),
                    );
                  }

                  final room = snapshot.data!;
                  final isHost = currentUser?.uid == room.hostId;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Players Section
                        _buildSection(
                          title: 'players',
                          trailing: '${room.playerCount}/${room.maxPlayers}',
                          child: _buildPlayersGrid(room),
                        ),
                        const SizedBox(height: 16),

                        // Game Settings Section (Host only) + QR Code side by side
                        if (isHost)
                          _buildHostSettingsWithQR(room)
                        else
                          _buildGuestView(room),

                        const SizedBox(height: 16),

                        // Categories Section (Host only)
                        if (isHost)
                          _buildSection(
                            title: 'Categories',
                            child: _buildCategoriesGrid(room),
                          ),

                        const SizedBox(height: 16),

                        // Start Game / Leave Button
                        _buildBottomButtons(room, isHost),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22D3EE), width: 3),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF05396B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                const Icon(Icons.expand_less, color: Colors.white),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersGrid(Room room) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: room.players.map((p) {
        final isPlayerHost = p['uid'] == room.hostId;
        final playerAvatar = p['avatar'] as String?;
        final playerName = p['name'] ?? 'Player';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: playerAvatar != null
                      ? ClipOval(
                          child: Image.asset(
                            'lib/assets/$playerAvatar',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            playerName.isNotEmpty
                                ? playerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                if (isPlayerHost)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9A223),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              playerName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isPlayerHost ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHostSettingsWithQR(Room room) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout on narrow screens
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSection(
                title: 'Game settings',
                child: _buildGameSettings(room),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQRCode(room)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShareButton(room)),
                ],
              ),
            ],
          );
        }
        // Wide screens: side by side
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSection(
                title: 'Game settings',
                child: _buildGameSettings(room),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildQRCode(room),
                  const SizedBox(height: 12),
                  _buildShareButton(room),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestView(Room room) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout on narrow screens
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSection(
                title: 'Game settings',
                child: _buildReadOnlySettings(room),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQRCode(room)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShareButton(room)),
                ],
              ),
            ],
          );
        }
        // Wide screens: side by side
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSection(
                title: 'Game settings',
                child: _buildReadOnlySettings(room),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildQRCode(room),
                  const SizedBox(height: 12),
                  _buildShareButton(room),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlySettings(Room room) {
    return Column(
      children: [
        _buildSettingRow('Tour time:', '${room.tourTime} seconds'),
        const SizedBox(height: 12),
        _buildSettingRow('Rounds:', '${room.numberOfRounds}'),
        const SizedBox(height: 12),
        _buildSettingRow('Max players:', '${room.maxPlayers}'),
        const SizedBox(height: 12),
        _buildSettingRow('TV mode:', room.tvSettings ? 'On' : 'Off'),
        const SizedBox(height: 12),
        _buildSettingRow('Regulator:', room.regulatorSetting ? 'On' : 'Off'),
        if (room.selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white38),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Categories: ${room.selectedCategories.length} selected',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: room.selectedCategories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildGameSettings(Room room) {
    return Column(
      children: [
        // Tour time
        _buildDropdownSetting(
          label: 'second',
          value: room.tourTime,
          items: [15, 30, 45, 60, 90, 120],
          suffix: 'Tour time:',
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              tourTime: val,
            );
          },
        ),
        const SizedBox(height: 12),

        // Number of rounds
        _buildDropdownSetting(
          label: 'round',
          value: room.numberOfRounds,
          items: [5, 10, 15, 20, 25, 30],
          suffix: 'Number of rounds:',
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              numberOfRounds: val,
            );
          },
          isVip: true,
        ),
        const SizedBox(height: 12),

        // Number of players
        _buildDropdownSetting(
          label: 'player',
          value: room.maxPlayers,
          items: [2, 3, 4, 5, 6, 7, 8, 9, 10],
          suffix: 'Number of players:',
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              maxPlayers: val,
            );
          },
        ),
        const SizedBox(height: 16),

        // TV Settings toggle
        _buildToggleSetting(
          label: 'TV settings:',
          value: room.tvSettings,
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              tvSettings: val,
            );
          },
        ),
        const SizedBox(height: 12),

        // Regulator setting toggle
        _buildToggleSetting(
          label: 'Regulator setting:',
          value: room.regulatorSetting,
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              regulatorSetting: val,
            );
          },
          description:
              'The room owner is allowed to organize the game without playing with the other players. This is typically for competitions and tournaments.',
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String label,
    required int value,
    required List<int> items,
    required String suffix,
    required Function(int) onChanged,
    bool isVip = false,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox(),
            isDense: true,
            items: items.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text('$e', style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
        if (isVip) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFD9A223),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'VIP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            suffix,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF2DD4BF),
              inactiveThumbColor: const Color(0xFF0E5F88),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildQRCode(Room room) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: '$_shareLink\nCode: ${room.code}',
        version: QrVersions.auto,
        size: 120,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildShareButton(Room room) {
    return Column(
      children: [
        _buildGradientButton(
          icon: Icons.share,
          label: 'Share room link',
          onTap: () => _shareRoom(room.code),
        ),
        const SizedBox(height: 12),
        _buildGradientButton(
          icon: Icons.copy,
          label: 'Copy link',
          onTap: () => _copyLink(room.code),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2DD4BF), // Teal/cyan
            Color(0xFF6366F1), // Purple/indigo
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF22D3EE), // Cyan border
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFFE0E0E0), size: 22),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E0E0),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(Room room) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allCategories.map((cat) {
        final name = cat['name'] as String;
        final isVip = cat['isVip'] as bool;
        final isSelected = room.selectedCategories.contains(name);

        return GestureDetector(
          onTap: () {
            _roomService.toggleCategory(roomId: widget.roomId, category: name);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0E5F88),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF22D3EE) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isVip) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9A223),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons(Room room, bool isHost) {
    return Column(
      children: [
        // Start Game button (Host only)
        if (isHost)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: room.selectedCategories.isNotEmpty
                  ? () {
                      // TODO: Start game logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting game...')),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9A223),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD9A223).withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                room.selectedCategories.isEmpty
                    ? 'Select categories to start'
                    : 'Start Game',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (isHost) const SizedBox(height: 12),

        // Leave/Close Room button
        _buildGradientButton(
          icon: Icons.exit_to_app,
          label: isHost ? 'Close Room' : 'Leave Room',
          onTap: _leaveRoom,
        ),
      ],
    );
  }
}
