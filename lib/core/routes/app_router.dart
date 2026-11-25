import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/author/publish_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../services/auth_service.dart';
import '../widgets/main_shell.dart';
import '../widgets/placeholder_screen.dart';
import 'auth_refresh.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthRefreshNotifier(
    AuthService.instance.authStateChanges,
  ),
  redirect: (context, state) {
    final connecte = AuthService.instance.currentSession != null;
    final chemin = state.matchedLocation;
    final surPageAuth = chemin == '/connexion' || chemin == '/inscription';

    if (!connecte && !surPageAuth) return '/connexion';
    if (connecte && surPageAuth) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/connexion',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/inscription',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/modifier-profil',
      builder: (context, state) => EditProfileScreen(
        profile: (state.extra as Map<String, dynamic>?) ?? {},
      ),
    ),
    GoRoute(
      path: '/publier',
      builder: (context, state) => const PublishWorkScreen(),
    ),
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
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);