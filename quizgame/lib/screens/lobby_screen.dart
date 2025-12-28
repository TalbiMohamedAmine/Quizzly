import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/room_service.dart';
import '../services/game_service.dart';
import '../models/room.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomService = RoomService();
  final _gameService = GameService();
  bool _leaving = false;
  bool _startingGame = false;

  // Available categories
  static const List<String> _allCategories = [ 'Labobo', 
  'Strange questions', 'General information', 'Sciences', 
  'Who is the famous person?', 'Arts', 'Soccer', 'Sports', 'Geography', 
  'Information', 'Literature', 'Date', 'Video games', 'Cartoon', 'TV series', 
  'Films', 'Fashion world', 'Digital currencies', 'Technology', 'Currency', 
  'Slogans',  'Products', 'Fruits and vegetables', 'Proverbs and riddles', 
  'Ramadan Nights', 'Characters', 'Cars', 'Food', 'Mathematics', 'Plants', 
  'Astronomy and space', 'General medicine', 'Math puzzles', 'Physics', 
  'Inventors and inventions', 'Memes', 'Mythical Creatures', 'Brain rots', 
  'Anime & Manga', 'Trends'];


  String _getShareLink(String code) => 'https://quiz-duel-1b09b.web.app/?join=$code';

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
    final link = _getShareLink(code);
    await Share.share(
      'Join my Quiz Game room!\nRoom Code: $code\nLink: $link',
      subject: 'Join my Quiz Game!',
    );
  }

  void _copyLink(String code) {
    final link = _getShareLink(code);
    Clipboard.setData(ClipboardData(text: 'Room Code: $code\n$link'));
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

                  // If room state is 'playing' or 'starting' and we have a gameId,
                  // navigate to game screen (for non-host players)
                  if ((room.state == 'playing' || room.state == 'starting') && 
                      room.gameId != null && 
                      !isHost &&
                      !_startingGame) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              gameId: room.gameId!,
                              roomId: room.id,
                            ),
                          ),
                        );
                      }
                    });
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Game is starting...',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Players Section
                        CollapsibleSection(
                          title: 'Players',
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
                          CollapsibleSection(
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

  Widget _buildPlayersGrid(Room room) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
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
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPlayerHost
                          ? const Color(0xFFD9A223)
                          : const Color(0xFF22D3EE),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPlayerHost
                                ? const Color(0xFFD9A223)
                                : const Color(0xFF22D3EE))
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                ),
                if (isPlayerHost)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9A223),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFD9A223),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 90,
              child: Text(
                playerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isPlayerHost ? FontWeight.bold : FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
              CollapsibleSection(
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
              child: CollapsibleSection(
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
              CollapsibleSection(
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
              child: CollapsibleSection(
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
        const SizedBox(height: 16),
        _buildSettingRow('Rounds:', '${room.numberOfRounds}'),
        const SizedBox(height: 16),
        _buildSettingRow('Max players:', '${room.maxPlayers}'),
        const SizedBox(height: 16),
        _buildSettingRow('TV mode:', room.tvSettings ? 'On' : 'Off'),
        const SizedBox(height: 16),
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF22D3EE).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF22D3EE),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
        const SizedBox(height: 16),

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
        ),
        const SizedBox(height: 16),

        // Number of players
        _buildDropdownSetting(
          label: 'player',
          value: room.maxPlayers,
          items: [5, 10, 20, 25, 30, 50],
          suffix: 'Max players:',
          onChanged: (val) {
            _roomService.updateRoomSettings(
              roomId: widget.roomId,
              maxPlayers: val,
            );
          },
        ),
        const SizedBox(height: 20),

        
        const SizedBox(height: 12),
        // Regulator setting toggle
        _buildToggleSetting(
          label: 'Regulator setting',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          suffix,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A4A6F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF22D3EE).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: DropdownButton<int>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            iconEnabledColor: const Color(0xFF22D3EE),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            items: items.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text('$e'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
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
    final link = _getShareLink(room.code);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: QrImageView(
            data: link,
            version: QrVersions.auto,
            size: 140,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5F88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF22D3EE),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22D3EE).withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'ROOM CODE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                room.code,
                style: const TextStyle(
                  color: Color(0xFF22D3EE),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton(Room room) {
    return Column(
      children: [
        _buildGradientButton(
          icon: Icons.share,
          label: 'Share link',
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFFE0E0E0), size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE0E0E0),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
    return _CategoriesGrid(
      roomId: widget.roomId,
      selectedCategories: room.selectedCategories,
      allCategories: _allCategories,
      customCategories: room.customCategories,
      roomService: _roomService,
    );
  }

  Future<void> _startGame(Room room) async {
    if (_startingGame) return;

    // Check if regulator setting is enabled and there are no other players
    if (room.regulatorSetting && room.playerCount <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regulator mode activated! At least one other player is needed.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _startingGame = true);

    try {
      final game = await _gameService.startGame(room: room);
      
      if (mounted) {
        // Navigate to game screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameId: game.id,
              roomId: room.id,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _startingGame = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start game: $e')),
        );
      }
    }
  }

  Widget _buildBottomButtons(Room room, bool isHost) {
    return Column(
      children: [
        // Start Game button (Host only)
        if (isHost)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: room.selectedCategories.isNotEmpty
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD9A223),
                        Color(0xFFF4C430),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD9A223).withOpacity(0.5),
                        const Color(0xFFF4C430).withOpacity(0.5),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: room.selectedCategories.isNotEmpty
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD9A223).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: room.selectedCategories.isNotEmpty && !_startingGame
                    ? () => _startGame(room)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _startingGame
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Generating Questions...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          room.selectedCategories.isEmpty
                              ? 'Select categories to start'
                              : 'START GAME',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        if (isHost) const SizedBox(height: 16),

        // Leave/Close Room button
        _buildGradientButton(
          icon: Icons.exit_to_app,
          label: isHost ? 'Close Room' : 'Leave Room',
          onTap: _leaving || _startingGame ? () {} : _leaveRoom,
        ),
      ],
    );
  }
}

/// A self-contained collapsible section widget that manages its own expansion state
class CollapsibleSection extends StatefulWidget {
  final String title;
  final String? trailing;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF22D3EE).withOpacity(0.6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF05396B),
                borderRadius: _isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      )
                    : BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (widget.trailing != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF22D3EE).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.trailing!,
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_less,
                      color: Color(0xFF22D3EE),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.all(18),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Isolated widget for categories grid with its own optimistic state
class _CategoriesGrid extends StatefulWidget {
  final String roomId;
  final List<String> selectedCategories;
  final List<String> allCategories;
  final List<String> customCategories;
  final RoomService roomService;

  const _CategoriesGrid({
    required this.roomId,
    required this.selectedCategories,
    required this.allCategories,
    required this.customCategories,
    required this.roomService,
  });

  @override
  State<_CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<_CategoriesGrid> {
  late Set<String> _localCategories;
  late List<String> _localCustomCategories;
  Set<String> _pendingToggles = {};

  @override
  void initState() {
    super.initState();
    _localCategories = widget.selectedCategories.toSet();
    _localCustomCategories = List<String>.from(widget.customCategories);
  }

  @override
  void didUpdateWidget(_CategoriesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync categories that are NOT currently being toggled
    if (_pendingToggles.isEmpty) {
      _localCategories = widget.selectedCategories.toSet();
      _localCustomCategories = List<String>.from(widget.customCategories);
    } else {
      // Merge server state but keep pending toggles
      final serverCategories = widget.selectedCategories.toSet();
      final allCats = [...widget.allCategories, ...widget.customCategories];
      for (final name in allCats) {
        if (!_pendingToggles.contains(name)) {
          if (serverCategories.contains(name)) {
            _localCategories.add(name);
          } else {
            _localCategories.remove(name);
          }
        }
      }
      // Update custom categories
      _localCustomCategories = List<String>.from(widget.customCategories);
    }
  }

  void _toggleCategory(String name) {
    setState(() {
      _pendingToggles.add(name);
      if (_localCategories.contains(name)) {
        _localCategories.remove(name);
      } else {
        _localCategories.add(name);
      }
    });
    
    // Update Firestore and clear pending when done
    widget.roomService.toggleCategory(roomId: widget.roomId, category: name).then((_) {
      if (mounted) {
        setState(() => _pendingToggles.remove(name));
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _pendingToggles.remove(name));
      }
    });
  }

  void _showAddCustomCategoryDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E5F88),
        title: const Text(
          'Add Custom Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter category name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF22D3EE),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF22D3EE),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          cursorColor: const Color(0xFF22D3EE),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF22D3EE)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final categoryName = controller.text.trim();
              if (categoryName.isNotEmpty && 
                  !_localCustomCategories.contains(categoryName) &&
                  !widget.allCategories.contains(categoryName)) {
                await widget.roomService.addCustomCategory(
                  roomId: widget.roomId,
                  categoryName: categoryName,
                );
                // Auto-select the custom category
                await widget.roomService.toggleCategory(
                  roomId: widget.roomId,
                  category: categoryName,
                );
                if (mounted) {
                  setState(() {
                    _localCustomCategories.add(categoryName);
                    _localCategories.add(categoryName);
                  });
                  Navigator.pop(context);
                }
              } else if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a category name')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This category already exists')),
                );
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom categories first, then all categories
    final allCategoriesToDisplay = [
      ..._localCustomCategories,
      ...widget.allCategories,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Add custom category button
            GestureDetector(
              onTap: _showAddCustomCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A4A6F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF),
                    width: 2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Color(0xFF2DD4BF), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Custom',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // All categories (custom first, then default)
            ...allCategoriesToDisplay.map((name) {
              final isSelected = _localCategories.contains(name);
              final isCustom = _localCustomCategories.contains(name);

              return GestureDetector(
                onTap: () => _toggleCategory(name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF0A4A6F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22D3EE)
                          : isCustom
                            ? const Color(0xFF2DD4BF).withOpacity(0.5)
                            : const Color(0xFF22D3EE).withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isCustom)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.star,
                            color: Color(0xFF2DD4BF),
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}
