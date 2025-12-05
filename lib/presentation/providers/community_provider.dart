import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/prayer_request_model.dart';
import '../../data/models/testimony_model.dart';
import '../../data/repositories/community_repository.dart';

/// Provider para el repositorio de comunidad
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

/// Estado de la comunidad
class CommunityState {
  final List<PrayerRequest> prayerRequests;
  final List<Testimony> testimonies;
  final List<dynamic> events;
  final bool isLoading;
  final String? error;
  final Map<String, bool> prayedRequests;
  final Map<String, bool> likedTestimonies;

  const CommunityState({
    this.prayerRequests = const [],
    this.testimonies = const [],
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.prayedRequests = const {},
    this.likedTestimonies = const {},
  });

  CommunityState copyWith({
    List<PrayerRequest>? prayerRequests,
    List<Testimony>? testimonies,
    List<dynamic>? events,
    bool? isLoading,
    String? error,
    Map<String, bool>? prayedRequests,
    Map<String, bool>? likedTestimonies,
  }) {
    return CommunityState(
      prayerRequests: prayerRequests ?? this.prayerRequests,
      testimonies: testimonies ?? this.testimonies,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      prayedRequests: prayedRequests ?? this.prayedRequests,
      likedTestimonies: likedTestimonies ?? this.likedTestimonies,
    );
  }
}

/// Notifier de comunidad
class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;

  CommunityNotifier(this._repository) : super(const CommunityState());

  /// Cargar peticiones de oración
  Future<void> loadPrayerRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _repository.getPrayerRequests();
      state = state.copyWith(
        prayerRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cargar testimonios
  Future<void> loadTestimonies() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final testimonies = await _repository.getTestimonies();
      state = state.copyWith(
        testimonies: testimonies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cargar eventos
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _repository.getEvents();
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Orar por una petición
  Future<void> prayForRequest(String requestId) async {
    final isPraying = state.prayedRequests[requestId] ?? false;

    // Actualizar estado optimistamente
    final updatedPrayedRequests = Map<String, bool>.from(state.prayedRequests);
    updatedPrayedRequests[requestId] = !isPraying;

    final updatedRequests = state.prayerRequests.map((request) {
      if (request.id == requestId) {
        return request.copyWith(
          prayerCount: isPraying
              ? request.prayerCount - 1
              : request.prayerCount + 1,
          hasPrayed: !isPraying,
        );
      }
      return request;
    }).toList();

    state = state.copyWith(
      prayedRequests: updatedPrayedRequests,
      prayerRequests: updatedRequests,
    );

    try {
      if (!isPraying) {
        await _repository.prayForRequest(requestId);
      } else {
        await _repository.unprayForRequest(requestId);
      }
    } catch (e) {
      // Revertir en caso de error
      state = state.copyWith(
        prayedRequests: state.prayedRequests,
        prayerRequests: state.prayerRequests,
      );
    }
  }

  /// Dar like a un testimonio
  Future<void> likeTestimony(String testimonyId) async {
    final isLiked = state.likedTestimonies[testimonyId] ?? false;

    // Actualizar estado optimistamente
    final updatedLikedTestimonies = Map<String, bool>.from(state.likedTestimonies);
    updatedLikedTestimonies[testimonyId] = !isLiked;

    final updatedTestimonies = state.testimonies.map((testimony) {
      if (testimony.id == testimonyId) {
        return testimony.copyWith(
          likesCount: isLiked
              ? testimony.likesCount - 1
              : testimony.likesCount + 1,
          hasLiked: !isLiked,
        );
      }
      return testimony;
    }).toList();

    state = state.copyWith(
      likedTestimonies: updatedLikedTestimonies,
      testimonies: updatedTestimonies,
    );

    try {
      if (!isLiked) {
        await _repository.likeTestimony(testimonyId);
      } else {
        await _repository.unlikeTestimony(testimonyId);
      }
    } catch (e) {
      // Revertir en caso de error
      state = state.copyWith(
        likedTestimonies: state.likedTestimonies,
        testimonies: state.testimonies,
      );
    }
  }

  /// Crear petición de oración
  Future<void> createPrayerRequest({
    required String title,
    required String content,
    String? category,
    bool isAnonymous = false,
    bool isUrgent = false,
    List<String>? tags,
    String? bibleReference,
  }) async {
    try {
      final request = await _repository.createPrayerRequest(
        title: title,
        content: content,
        category: category,
        isAnonymous: isAnonymous,
        isUrgent: isUrgent,
        tags: tags,
        bibleReference: bibleReference,
      );

      state = state.copyWith(
        prayerRequests: [request, ...state.prayerRequests],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Crear testimonio
  Future<void> createTestimony({
    required String title,
    required String content,
    String? category,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
    String? bibleReference,
    List<String>? beforeImages,
    List<String>? afterImages,
  }) async {
    try {
      final testimony = await _repository.createTestimony(
        title: title,
        content: content,
        category: category,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        tags: tags,
        bibleReference: bibleReference,
        beforeImages: beforeImages,
        afterImages: afterImages,
      );

      state = state.copyWith(
        testimonies: [testimony, ...state.testimonies],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Eliminar petición de oración
  Future<void> deletePrayerRequest(String requestId) async {
    try {
      await _repository.deletePrayerRequest(requestId);

      state = state.copyWith(
        prayerRequests: state.prayerRequests
            .where((r) => r.id != requestId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Eliminar testimonio
  Future<void> deleteTestimony(String testimonyId) async {
    try {
      await _repository.deleteTestimony(testimonyId);

      state = state.copyWith(
        testimonies: state.testimonies
            .where((t) => t.id != testimonyId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider principal de comunidad
final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  return CommunityNotifier(repository);
});

/// Provider para peticiones de oración
final prayerRequestsProvider = FutureProvider<List<PrayerRequest>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getPrayerRequests();
});

/// Provider para peticiones de oración por categoría
final prayerRequestsByCategoryProvider = FutureProvider.family<List<PrayerRequest>, String>(
  (ref, category) async {
    final repository = ref.watch(communityRepositoryProvider);
    return repository.getPrayerRequestsByCategory(category);
  },
);

/// Provider para testimonios
final testimoniesProvider = FutureProvider<List<Testimony>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getTestimonies();
});

/// Provider para testimonios destacados
final featuredTestimoniesProvider = FutureProvider<List<Testimony>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getFeaturedTestimonies();
});

/// Provider para testimonios por categoría
final testimoniesByCategoryProvider = FutureProvider.family<List<Testimony>, String>(
  (ref, category) async {
    final repository = ref.watch(communityRepositoryProvider);
    return repository.getTestimoniesByCategory(category);
  },
);

/// Provider para eventos
final eventsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getEvents();
});

/// Provider para estadísticas de comunidad
final communityStatisticsProvider = FutureProvider<CommunityStatistics>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getStatistics();
});

/// Modelo de estadísticas de comunidad
class CommunityStatistics {
  final int totalPrayerRequests;
  final int totalTestimonies;
  final int totalEvents;
  final int totalPrayers;
  final int totalUsers;
  final Map<String, int> prayersByCategory;
  final Map<String, int> testimoniesByCategory;
  final List<PrayerRequest> urgentRequests;
  final List<Testimony> recentTestimonies;

  const CommunityStatistics({
    required this.totalPrayerRequests,
    required this.totalTestimonies,
    required this.totalEvents,
    required this.totalPrayers,
    required this.totalUsers,
    required this.prayersByCategory,
    required this.testimoniesByCategory,
    required this.urgentRequests,
    required this.recentTestimonies,
  });
}