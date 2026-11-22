import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../widgets/main_shell.dart';
import '../widgets/placeholder_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const PlaceholderScreen(
                title: 'Accueil',
                icon: Icons.home,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recherche',
              builder: (context, state) => const PlaceholderScreen(
                title: 'Recherche',
                icon: Icons.search,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bibliotheque',
              builder: (context, state) => const PlaceholderScreen(
                title: 'Bibliothèque',
                icon: Icons.local_library,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profil',
              builder: (context, state) => const PlaceholderScreen(
                title: 'Profil',
                icon: Icons.person,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);