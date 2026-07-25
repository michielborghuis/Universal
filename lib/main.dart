import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Counter',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111318),
        cardTheme: const CardThemeData(
          color: Color(0xFF1B1E25),
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
      ),
      home: const CounterHome(),
    );
  }
}

enum LeaderHighlightMode {
  none,
  highestScore,
  highestCounter,
}

class ScoreButtonConfig {
  ScoreButtonConfig({
    required this.value,
    this.incrementsCounter = false,
  });

  int value;
  bool incrementsCounter;

  Map<String, dynamic> toJson() => {
        'value': value,
        'incrementsCounter': incrementsCounter,
      };

  factory ScoreButtonConfig.fromJson(Map<String, dynamic> json) =>
      ScoreButtonConfig(
        value: json['value'] as int? ?? 0,
        incrementsCounter: json['incrementsCounter'] as bool? ?? false,
      );
}

class Player {
  Player({
    required this.name,
    this.score = 0,
    this.counter = 0,
    this.colorIndex = 0,
  });

  String name;
  int score;
  int counter;
  int colorIndex;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'counter': counter,
        'colorIndex': colorIndex,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'] as String? ?? 'Speler',
        score: json['score'] as int? ?? 0,
        counter: json['counter'] as int? ?? 0,
        colorIndex: json['colorIndex'] as int? ?? 0,
      );
}

class GameConfig {
  GameConfig({
    required this.id,
    required this.name,
    required this.buttons,
    this.useBigPlus = false,
    this.useBigMinus = false,
    this.bigStep = 1,
    this.showCounter = false,
    this.counterLabel = 'Teller',
    this.counterIcon = true,
    this.highlightMode = LeaderHighlightMode.none,
    this.usePlayerColors = true,
    List<Player>? players,
  }) : players = players ?? [];

  String id;
  String name;
  List<ScoreButtonConfig> buttons;
  bool useBigPlus;
  bool useBigMinus;
  int bigStep;
  bool showCounter;
  String counterLabel;
  bool counterIcon;
  LeaderHighlightMode highlightMode;
  bool usePlayerColors;
  List<Player> players;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buttons': buttons.map((b) => b.toJson()).toList(),
        'useBigPlus': useBigPlus,
        'useBigMinus': useBigMinus,
        'bigStep': bigStep,
        'showCounter': showCounter,
        'counterLabel': counterLabel,
        'counterIcon': counterIcon,
        'highlightMode': highlightMode.name,
        'usePlayerColors': usePlayerColors,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    final rawMode = json['highlightMode'] as String?;
    final oldHighlight = json['highlightLeader'] as bool? ?? false;
    var mode = LeaderHighlightMode.none;
    if (rawMode != null) {
      mode = LeaderHighlightMode.values.firstWhere(
        (item) => item.name == rawMode,
        orElse: () => LeaderHighlightMode.none,
      );
    } else if (oldHighlight) {
      mode = LeaderHighlightMode.highestScore;
    }

    return GameConfig(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Spel',
      buttons: ((json['buttons'] as List<dynamic>?) ?? [])
          .map((b) => ScoreButtonConfig.fromJson(b as Map<String, dynamic>))
          .toList(),
      useBigPlus: json['useBigPlus'] as bool? ?? false,
      useBigMinus: json['useBigMinus'] as bool? ?? false,
      bigStep: json['bigStep'] as int? ?? 1,
      showCounter: json['showCounter'] as bool? ?? false,
      counterLabel: json['counterLabel'] as String? ?? 'Teller',
      counterIcon: json['counterIcon'] as bool? ?? true,
      highlightMode: mode,
      usePlayerColors: json['usePlayerColors'] as bool? ?? true,
      players: ((json['players'] as List<dynamic>?) ?? [])
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CounterHome extends StatefulWidget {
  const CounterHome({super.key});

  @override
  State<CounterHome> createState() => _CounterHomeState();
}

class _CounterHomeState extends State<CounterHome> {
  static const _storageKey = 'counter_games_v2';

  final List<GameConfig> _games = [];
  int _selectedGame = 0;
  bool _loaded = false;
  List<GameConfig> _undoStack = [];

  static const playerColors = [
    Color(0xFFE67E00),
    Color(0xFFD9B91C),
    Color(0xFF2474C2),
    Color(0xFF8E24AA),
    Color(0xFF2E8B57),
    Color(0xFFC23B3B),
    Color(0xFF008C95),
    Color(0xFFD65A8A),
    Color(0xFF6D5BD0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  GameConfig get game => _games[_selectedGame];

  List<GameConfig> _defaultGames() => [
        GameConfig(
          id: 'dertigen',
          name: 'Dertigen',
          buttons: [
            ScoreButtonConfig(value: 1),
            ScoreButtonConfig(value: 10),
            ScoreButtonConfig(value: -15, incrementsCounter: true),
          ],
          useBigPlus: false,
          useBigMinus: false,
          showCounter: true,
          counterLabel: 'Gedronken',
          counterIcon: true,
          highlightMode: LeaderHighlightMode.highestCounter,
        ),
        GameConfig(
          id: 'tienduizenden',
          name: 'Tienduizenden',
          buttons: [
            ScoreButtonConfig(value: 50),
            ScoreButtonConfig(value: 200),
          ],
          useBigPlus: false,
          useBigMinus: false,
          showCounter: false,
          highlightMode: LeaderHighlightMode.highestScore,
        ),
      ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    try {
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final items = decoded['games'] as List<dynamic>? ?? [];
        _games.addAll(
          items.map((g) => GameConfig.fromJson(g as Map<String, dynamic>)),
        );
        _selectedGame = decoded['selectedGame'] as int? ?? 0;
      }
    } catch (_) {
      _games.clear();
    }

    if (_games.isEmpty) {
      _games.addAll(_defaultGames());
      _selectedGame = 0;
      await _save();
    }

    if (_selectedGame >= _games.length) _selectedGame = 0;

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'selectedGame': _selectedGame,
        'games': _games.map((g) => g.toJson()).toList(),
      }),
    );
  }

  void _remember() {
    final copied = jsonDecode(jsonEncode(_games.map((g) => g.toJson()).toList()))
        as List<dynamic>;
    _undoStack = copied
        .map((g) => GameConfig.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<void> _undo() async {
    if (_undoStack.isEmpty) return;
    setState(() {
      _games
        ..clear()
        ..addAll(_undoStack);
      if (_selectedGame >= _games.length) _selectedGame = 0;
      _undoStack = [];
    });
    await _save();
  }

  Future<String?> _askText(
    String title, {
    String initial = '',
    String label = 'Naam',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: label,
            helperText: 'Maximaal 10 tekens',
          ),
          onSubmitted: (value) {
            final text = value.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPlayer() async {
    final name = await _askText('Speler toevoegen');
    if (name == null) return;
    _remember();
    setState(() {
      game.players.add(
        Player(name: name, colorIndex: game.players.length),
      );
    });
    await _save();
  }

  Future<void> _editScore(int index) async {
    final controller =
        TextEditingController(text: game.players[index].score.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Score van ${game.players[index].name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(labelText: 'Nieuwe score'),
          onSubmitted: (value) {
            final parsed = int.tryParse(value.trim());
            if (parsed != null) Navigator.pop(context, parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) Navigator.pop(context, parsed);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    if (value == null) return;
    _remember();
    setState(() => game.players[index].score = value);
    await _save();
  }

  Future<void> _applyScore(
    int playerIndex,
    int amount, {
    bool incrementCounter = false,
  }) async {
    _remember();
    setState(() {
      game.players[playerIndex].score += amount;
      if (incrementCounter) {
        game.players[playerIndex].counter += 1;
      }
    });
    await _save();
  }

  Future<void> _editPlayerName(int index) async {
    final name = await _askText(
      'Naam wijzigen',
      initial: game.players[index].name,
    );
    if (name == null) return;

    _remember();
    setState(() => game.players[index].name = name);
    await _save();
  }

  Future<void> _editCounter(int index) async {
    final controller =
        TextEditingController(text: game.players[index].counter.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${game.counterLabel} van ${game.players[index].name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(labelText: 'Nieuwe tellerwaarde'),
          onSubmitted: (value) {
            final parsed = int.tryParse(value.trim());
            if (parsed != null) Navigator.pop(context, parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) Navigator.pop(context, parsed);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    if (value == null) return;
    _remember();
    setState(() => game.players[index].counter = value < 0 ? 0 : value);
    await _save();
  }

  Future<void> _openDeletePlayers() async {
    if (game.players.isEmpty) return;
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (context) => _DeletePlayersDialog(players: game.players),
    );
    if (selected == null || selected.isEmpty) return;

    _remember();
    setState(() {
      final indices = selected.toList()..sort((a, b) => b.compareTo(a));
      for (final index in indices) {
        game.players.removeAt(index);
      }
    });
    await _save();
  }

  Future<void> _resetGame() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw spel starten?'),
        content: const Text(
          'Alle scores en tellers worden op nul gezet. Spelers blijven staan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    _remember();
    setState(() {
      for (final player in game.players) {
        player.score = 0;
        player.counter = 0;
      }
    });
    await _save();
  }

  Future<void> _openGameEditor({GameConfig? existing}) async {
    final result = await showDialog<GameConfig>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameEditorDialog(existing: existing),
    );

    if (result == null) return;

    _remember();
    setState(() {
      if (existing == null) {
        _games.add(result);
        _selectedGame = _games.length - 1;
      } else {
        final index = _games.indexWhere((g) => g.id == existing.id);
        result.players = existing.players;
        if (index >= 0) _games[index] = result;
      }
    });
    await _save();
  }

  Future<void> _deleteCurrentGame() async {
    if (_games.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Er moet minstens één spel blijven.')),
      );
      return;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${game.name} verwijderen?'),
        content: const Text('Ook de spelers en scores van dit spel verdwijnen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (yes != true) return;
    _remember();
    setState(() {
      _games.removeAt(_selectedGame);
      _selectedGame = 0;
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final highestScore = game.players.isEmpty
        ? null
        : game.players
            .map((player) => player.score)
            .reduce((a, b) => a > b ? a : b);
    final highestCounter = game.players.isEmpty
        ? null
        : game.players
            .map((player) => player.counter)
            .reduce((a, b) => a > b ? a : b);

    bool isHighlighted(Player player) {
      switch (game.highlightMode) {
        case LeaderHighlightMode.none:
          return false;
        case LeaderHighlightMode.highestScore:
          return highestScore != null && player.score == highestScore;
        case LeaderHighlightMode.highestCounter:
          return highestCounter != null &&
              highestCounter > 0 &&
              player.counter == highestCounter;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          game.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Speler toevoegen',
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            tooltip: 'Spelers verwijderen',
            onPressed: game.players.isEmpty ? null : _openDeletePlayers,
            icon: const Icon(Icons.person_remove_alt_1_rounded),
          ),
          IconButton(
            tooltip: 'Ongedaan maken',
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') _openGameEditor(existing: game);
              if (value == 'reset') _resetGame();
              if (value == 'delete') _deleteCurrentGame();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Spelinstellingen'),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Text('Scores resetten'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Spel verwijderen'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text(
                  'Spellen',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _games.length,
                  itemBuilder: (context, index) => ListTile(
                    selected: index == _selectedGame,
                    leading: const Icon(Icons.casino_rounded),
                    title: Text(_games[index].name),
                    onTap: () {
                      setState(() => _selectedGame = index);
                      _save();
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      tooltip: 'Spel aanpassen',
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () {
                        Navigator.pop(context);
                        _openGameEditor(existing: _games[index]);
                      },
                    ),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('Nieuw spel toevoegen'),
                onTap: () {
                  Navigator.pop(context);
                  _openGameEditor();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: game.players.isEmpty
            ? _EmptyState(onAdd: _addPlayer)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final count = game.players.length;
                  final columns = count <= 2 ? 1 : (count <= 4 ? 2 : 3);
                  final rows = (count / columns).ceil();
                  final shouldScroll = count > 9;
                  const spacing = 7.0;
                  const horizontalPadding = 10.0;
                  final bottomPadding =
                      MediaQuery.paddingOf(context).bottom + 12.0;

                  final usableWidth =
                      constraints.maxWidth - horizontalPadding * 2;
                  final cardWidth =
                      (usableWidth - spacing * (columns - 1)) / columns;
                  final availableHeight = shouldScroll
                      ? constraints.maxHeight
                      : constraints.maxHeight - bottomPadding;
                  final cardHeight = shouldScroll
                      ? 218.0
                      : (availableHeight - spacing * (rows - 1)) / rows;
                  final safeHeight = cardHeight.clamp(152.0, 330.0);
                  final compact = columns >= 2 || safeHeight < 245;
                  final veryCompact = columns == 3;

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    physics: shouldScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: cardWidth / safeHeight,
                    ),
                    itemCount: game.players.length,
                    itemBuilder: (context, index) {
                      final player = game.players[index];
                      return PlayerCard(
                        player: player,
                        game: game,
                        compact: compact,
                        veryCompact: veryCompact,
                        color: playerColors[
                            player.colorIndex % playerColors.length],
                        isLeader: isHighlighted(player),
                        onScoreTap: () => _editScore(index),
                        onNameTap: () => _editPlayerName(index),
                        onCounterTap: () => _editCounter(index),
                        onCustomButton: (button) => _applyScore(
                          index,
                          button.value,
                          incrementCounter: button.incrementsCounter,
                        ),
                        onBigPlus: () =>
                            _applyScore(index, game.bigStep.abs()),
                        onBigMinus: () =>
                            _applyScore(index, -game.bigStep.abs()),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.game,
    required this.compact,
    required this.veryCompact,
    required this.color,
    required this.isLeader,
    required this.onScoreTap,
    required this.onNameTap,
    required this.onCounterTap,
    required this.onCustomButton,
    required this.onBigPlus,
    required this.onBigMinus,
  });

  final Player player;
  final GameConfig game;
  final bool compact;
  final bool veryCompact;
  final Color color;
  final bool isLeader;
  final VoidCallback onScoreTap;
  final VoidCallback onNameTap;
  final VoidCallback onCounterTap;
  final ValueChanged<ScoreButtonConfig> onCustomButton;
  final VoidCallback onBigPlus;
  final VoidCallback onBigMinus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final playerColor = game.usePlayerColors ? color : colors.primary;
    final scoreSize = veryCompact ? 40.0 : (compact ? 48.0 : 62.0);
    final nameSize = veryCompact ? 13.0 : (compact ? 16.0 : 22.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isLeader ? const Color(0xFFFFD54F) : playerColor,
          width: isLeader ? 2.7 : 1.3,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onNameTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                if (game.showCounter)
                  InkWell(
                    onTap: onCounterTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 10,
                        vertical: compact ? 3 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (game.counterIcon) ...[
                            Icon(
                              Icons.sports_bar_rounded,
                              size: compact ? 13 : 17,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${player.counter}',
                            style: TextStyle(
                              fontSize: compact ? 12 : 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: InkWell(
                onTap: onScoreTap,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${player.score}',
                      style: TextStyle(
                        fontSize: scoreSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _DynamicButtonGrid(
              buttons: game.buttons,
              compact: compact,
              playerColor: playerColor,
              onTap: onCustomButton,
            ),
            if (game.useBigPlus || game.useBigMinus) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  if (game.useBigMinus)
                    Expanded(
                      child: SizedBox(
                        height: compact ? 40 : 48,
                        child: FilledButton.tonal(
                          onPressed: onBigMinus,
                          child: Text('-${game.bigStep.abs()}'),
                        ),
                      ),
                    ),
                  if (game.useBigMinus && game.useBigPlus)
                    const SizedBox(width: 7),
                  if (game.useBigPlus)
                    Expanded(
                      child: SizedBox(
                        height: compact ? 40 : 48,
                        child: FilledButton.tonal(
                          onPressed: onBigPlus,
                          child: Text('+${game.bigStep.abs()}'),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DynamicButtonGrid extends StatelessWidget {
  const _DynamicButtonGrid({
    required this.buttons,
    required this.compact,
    required this.playerColor,
    required this.onTap,
  });

  final List<ScoreButtonConfig> buttons;
  final bool compact;
  final Color playerColor;
  final ValueChanged<ScoreButtonConfig> onTap;

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    for (var index = 0; index < buttons.length; index += 2) {
      final remaining = buttons.length - index;
      final first = buttons[index];

      if (remaining == 1) {
        rows.add(
          SizedBox(
            width: double.infinity,
            child: _ScoreButton(
              button: first,
              compact: compact,
              backgroundColor: playerColor,
              foregroundColor:
                  first.value < 0 ? Colors.black : colors.onSurface,
              onTap: () => onTap(first),
            ),
          ),
        );
      } else {
        final second = buttons[index + 1];
        rows.add(
          Row(
            children: [
              Expanded(
                child: _ScoreButton(
                  button: first,
                  compact: compact,
                  backgroundColor: playerColor.withValues(alpha: 0.34),
                  foregroundColor: colors.onSurface,
                  onTap: () => onTap(first),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ScoreButton(
                  button: second,
                  compact: compact,
                  backgroundColor: playerColor.withValues(alpha: 0.50),
                  foregroundColor: colors.onSurface,
                  onTap: () => onTap(second),
                ),
              ),
            ],
          ),
        );
      }

      if (index + 2 < buttons.length) rows.add(const SizedBox(height: 7));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.button,
    required this.compact,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final ScoreButtonConfig button;
  final bool compact;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = button.value > 0 ? '+${button.value}' : '${button.value}';
    return SizedBox(
      height: compact ? 40 : 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 15 : 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class GameEditorDialog extends StatefulWidget {
  const GameEditorDialog({super.key, this.existing});

  final GameConfig? existing;

  @override
  State<GameEditorDialog> createState() => _GameEditorDialogState();
}

class _GameEditorDialogState extends State<GameEditorDialog> {
  late final TextEditingController nameController;
  late final TextEditingController buttonsController;
  late final TextEditingController stepController;
  late final TextEditingController counterLabelController;
  late final TextEditingController counterTriggerController;

  bool useBigPlus = false;
  bool useBigMinus = false;
  bool showCounter = false;
  bool counterIcon = true;
  bool usePlayerColors = true;
  LeaderHighlightMode highlightMode = LeaderHighlightMode.none;

  @override
  void initState() {
    super.initState();
    final game = widget.existing;
    nameController = TextEditingController(text: game?.name ?? '');
    buttonsController = TextEditingController(
      text: game?.buttons.map((b) => b.value).join(', ') ?? '',
    );
    stepController =
        TextEditingController(text: (game?.bigStep ?? 1).toString());
    counterLabelController =
        TextEditingController(text: game?.counterLabel ?? 'Teller');

    final trigger = game?.buttons
        .where((b) => b.incrementsCounter)
        .map((b) => b.value)
        .firstOrNull;
    counterTriggerController =
        TextEditingController(text: trigger?.toString() ?? '');

    useBigPlus = game?.useBigPlus ?? false;
    useBigMinus = game?.useBigMinus ?? false;
    showCounter = game?.showCounter ?? false;
    counterIcon = game?.counterIcon ?? true;
    usePlayerColors = game?.usePlayerColors ?? true;
    highlightMode = game?.highlightMode ?? LeaderHighlightMode.none;
  }

  List<int>? parseButtons() {
    final raw = buttonsController.text.trim();
    if (raw.isEmpty) return [];
    final values = <int>[];
    for (final part in raw.split(',')) {
      final value = int.tryParse(part.trim());
      if (value == null) return null;
      values.add(value);
    }
    return values;
  }

  void save() {
    final name = nameController.text.trim();
    final values = parseButtons();
    final step = int.tryParse(stepController.text.trim());
    final trigger = int.tryParse(counterTriggerController.text.trim());

    if (name.isEmpty || values == null || step == null || step == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Controleer de naam, knoppen en stapgrootte.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      GameConfig(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        buttons: values
            .map(
              (value) => ScoreButtonConfig(
                value: value,
                incrementsCounter:
                    showCounter && trigger != null && value == trigger,
              ),
            )
            .toList(),
        useBigPlus: useBigPlus,
        useBigMinus: useBigMinus,
        bigStep: step.abs(),
        showCounter: showCounter,
        counterIcon: counterIcon,
        highlightMode: highlightMode,
        usePlayerColors: usePlayerColors,
        counterLabel: counterLabelController.text.trim().isEmpty
            ? 'Teller'
            : counterLabelController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nieuw spel' : 'Spel aanpassen'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Naam van spel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buttonsController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Scoreknoppen',
                  hintText: 'Bijvoorbeeld: 1, 10, -15',
                  helperText: '1 breed; 2 naast elkaar; 3 als 2 + 1 breed; daarna rijen van 2.',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Grote plusknop gebruiken'),
                value: useBigPlus,
                onChanged: (value) => setState(() => useBigPlus = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Grote minknop gebruiken'),
                value: useBigMinus,
                onChanged: (value) => setState(() => useBigMinus = value),
              ),
              if (useBigPlus || useBigMinus)
                TextField(
                  controller: stepController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: false),
                  decoration: const InputDecoration(
                    labelText: 'Stapgrootte grote +/−',
                  ),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<LeaderHighlightMode>(
                initialValue: highlightMode,
                decoration: const InputDecoration(labelText: 'Gouden rand'),
                items: const [
                  DropdownMenuItem(
                    value: LeaderHighlightMode.none,
                    child: Text('Geen gouden rand'),
                  ),
                  DropdownMenuItem(
                    value: LeaderHighlightMode.highestScore,
                    child: Text('Hoogste score'),
                  ),
                  DropdownMenuItem(
                    value: LeaderHighlightMode.highestCounter,
                    child: Text('Hoogste extra teller'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => highlightMode = value ?? LeaderHighlightMode.none,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Extra teller bij speler tonen'),
                value: showCounter,
                onChanged: (value) => setState(() => showCounter = value),
              ),
              if (showCounter) ...[
                TextField(
                  controller: counterLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Naam van teller',
                    hintText: 'Bijvoorbeeld Gedronken',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: counterTriggerController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Teller verhogen bij scoreknop',
                    hintText: 'Bijvoorbeeld -15',
                    helperText:
                        'De teller stijgt wanneer deze knop wordt gebruikt.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Biersymbool bij teller tonen'),
                  value: counterIcon,
                  onChanged: (value) => setState(() => counterIcon = value),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verschillende spelerskleuren gebruiken'),
                value: usePlayerColors,
                onChanged: (value) => setState(() => usePlayerColors = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: save,
          child: const Text('Opslaan'),
        ),
      ],
    );
  }
}

class _DeletePlayersDialog extends StatefulWidget {
  const _DeletePlayersDialog({required this.players});

  final List<Player> players;

  @override
  State<_DeletePlayersDialog> createState() => _DeletePlayersDialogState();
}

class _DeletePlayersDialogState extends State<_DeletePlayersDialog> {
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Spelers verwijderen'),
      content: SizedBox(
        width: 420,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.players.length,
          itemBuilder: (context, index) => CheckboxListTile(
            value: selected.contains(index),
            title: Text(widget.players[index].name),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  selected.add(index);
                } else {
                  selected.remove(index);
                }
              });
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        FilledButton.tonal(
          onPressed: selected.isEmpty
              ? null
              : () => Navigator.pop(context, selected),
          child: const Text('Verwijderen'),
        ),
      ],
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, size: 74),
            const SizedBox(height: 16),
            const Text(
              'Nog geen spelers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voeg een speler toe om dit scorebord te gebruiken.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Speler toevoegen'),
            ),
          ],
        ),
      ),
    );
  }
}
