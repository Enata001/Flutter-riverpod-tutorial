import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;

  const Film({
    required this.id,
    required this.title,
    required this.description,
    required this.isFavorite,
  });

  Film copyWith({
    required bool isFavorite,
  }) {
    return Film(
      id: id,
      title: title,
      description: description,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isFavorite': isFavorite,
    };
  }

  factory Film.fromMap(Map<String, dynamic> map) {
    return Film(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isFavorite: map['isFavorite'] as bool,
    );
  }

  factory Film.fromString(String data) {
    return Film.fromMap(jsonDecode(data));
  }

  @override
  String toString() => jsonEncode(toMap());

  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([id, isFavorite]);
}

const List<Film> allFilms = [
  Film(
      id: '1',
      title: "The Shawshank Redemption",
      description: "Description of the Shawshank Redemption",
      isFavorite: false),
  Film(
      id: '2',
      title: "The Godfather",
      description: "Description of the Godfather",
      isFavorite: false),
  Film(
      id: '3',
      title: 'The Godfather Part II',
      description: "Description of the Godfather Part II",
      isFavorite: false),
  Film(
      id: '4',
      title: 'The Dark Knight',
      description: "Description of the Dark Knight",
      isFavorite: false),
  Film(
      id: '5',
      title: "Superman Returns",
      description: "Description of Superman Returns",
      isFavorite: false),
];

class FilmsNotifier extends StateNotifier<List<Film>> {
  FilmsNotifier() : super(allFilms);

  void update({required Film film, bool isFavorite = false}) {
    state = state
        .map((existingFilm) => existingFilm.id == film.id
            ? existingFilm.copyWith(isFavorite: isFavorite)
            : existingFilm)
        .toList();
  }
}

enum Status { all, favorite, notFavorite }

final statusProvider = StateProvider<Status>(
  (_) => Status.all,
);

final allFilmsProvider =
    StateNotifierProvider<FilmsNotifier, List<Film>>((_) => FilmsNotifier());

final favoriteFilmsProvider = Provider<Iterable<Film>>(
    (ref) => ref.watch(allFilmsProvider).where((film) => film.isFavorite));

final notFavoriteFilmsProvider = Provider<Iterable<Film>>(
    (ref) => ref.watch(allFilmsProvider).where((film) => !film.isFavorite));

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Films"),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const FilterWidget(),
          Consumer(builder: (context, ref, child) {
            final filter = ref.watch(statusProvider);

            switch (filter) {
              case Status.all:
                return FilmWidget(provider: allFilmsProvider);

              case Status.favorite:

                return FilmWidget(provider: favoriteFilmsProvider);
              case Status.notFavorite:

                return FilmWidget(provider: notFavoriteFilmsProvider);
            }
          })
        ],
      ),
    );
  }
}

class FilmWidget extends ConsumerWidget {
  final AlwaysAliveProviderBase<Iterable<Film>> provider;

  const FilmWidget({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final films = ref.watch(provider);
    return Expanded(
        child: ListView.builder(
            itemCount: films.length,
            itemBuilder: (builder, index) {
              final film = films.elementAt(index);
              final favoriteIcon = film.isFavorite
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.favorite_border);
              return ListTile(
                title: Text(film.title),
                subtitle: Text(film.description),
                trailing: IconButton(
                    onPressed: () {
                      final isFavorite = !film.isFavorite;
                      ref
                          .read(allFilmsProvider.notifier)
                          .update(film: film, isFavorite: isFavorite);
                    },
                    icon: favoriteIcon),
              );
            }));
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      return DropdownButton(
        items: Status.values
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e.name),
              ),
            )
            .toList(),
        onChanged: (element) {
          ref.read(statusProvider.notifier).state = element!;
        },
        value: ref.watch(statusProvider),
      );
    });
  }
}
