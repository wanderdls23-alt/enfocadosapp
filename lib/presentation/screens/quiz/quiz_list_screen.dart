import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  final String? courseId;
  final String? moduleId;

  const QuizListScreen({
    Key? key,
    this.courseId,
    this.moduleId,
  }) : super(key: key);

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  QuizType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseId != null
              ? 'Evaluaciones del Curso'
              : 'Mis Evaluaciones',
        ),
        backgroundColor: const Color(0xFFCC0000),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(text: 'PENDIENTES'),
            Tab(text: 'EN PROGRESO'),
            Tab(text: 'COMPLETADAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizList(QuizStatus.pending),
          _buildQuizList(QuizStatus.inProgress),
          _buildQuizList(QuizStatus.completed),
        ],
      ),
    );
  }

  Widget _buildQuizList(QuizStatus status) {
    final quizzesAsync = widget.courseId != null
        ? ref.watch(courseQuizzesProvider(widget.courseId!))
        : ref.watch(_allUserQuizzesProvider);

    return quizzesAsync.when(
      data: (quizzes) {
        final filteredQuizzes = _filterQuizzesByStatus(quizzes, status);

        if (filteredQuizzes.isEmpty) {
          return EmptyStateWidget(
            icon: _getEmptyStateIcon(status),
            title: _getEmptyStateTitle(status),
            message: _getEmptyStateMessage(status),
            actionLabel: status == QuizStatus.pending ? 'Explorar Cursos' : null,
            onAction: status == QuizStatus.pending
                ? () => context.push('/academy')
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (widget.courseId != null) {
              ref.invalidate(courseQuizzesProvider(widget.courseId!));
            } else {
              ref.invalidate(_allUserQuizzesProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredQuizzes.length,
            itemBuilder: (context, index) {
              final quizData = filteredQuizzes[index];
              return _buildQuizCard(quizData['quiz'], quizData['attempts']);
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.courseId != null) {
                  ref.invalidate(courseQuizzesProvider(widget.courseId!));
                } else {
                  ref.invalidate(_allUserQuizzesProvider);
                }
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz, List<QuizAttempt> attempts) {
    final eligibilityAsync = ref.watch(quizEligibilityProvider(quiz.id));
    final lastAttempt = attempts.isNotEmpty ? attempts.last : null;
    final bestAttempt = _getBestAttempt(attempts);
    final status = _getQuizStatus(quiz, attempts);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleQuizTap(quiz, eligibilityAsync.value, lastAttempt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  _buildQuizTypeIcon(quiz.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (quiz.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            quiz.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 16),

              // Información del quiz
              Row(
                children: [
                  _buildInfoChip(
                    Icons.quiz,
                    '${quiz.questions.length} preguntas',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.timer,
                    quiz.formattedTimeLimit,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.grade,
                    'Mínimo ${quiz.passingScore}%',
                  ),
                ],
              ),

              // Intentos y resultados
              if (attempts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intentos: ${attempts.length}/${quiz.maxAttempts == 0 ? '∞' : quiz.maxAttempts}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (bestAttempt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Mejor: ${bestAttempt.percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: bestAttempt.passed
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (lastAttempt != null) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Último intento',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastAttempt.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (lastAttempt != null &&
                          lastAttempt.status == QuizAttemptStatus.inProgress) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _calculateProgress(quiz, lastAttempt),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFCC0000)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Progreso: ${(_calculateProgress(quiz, lastAttempt) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Botones de acción
              const SizedBox(height: 16),
              eligibilityAsync.when(
                data: (eligibility) {
                  if (eligibility?.canTake ?? false) {
                    return _buildActionButton(
                      quiz,
                      lastAttempt,
                      status,
                      eligibility!,
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eligibility?.reason ?? 'No disponible',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                loading: () => const SizedBox(
                  height: 36,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTypeIcon(QuizType type) {
    IconData icon;
    Color color;

    switch (type) {
      case QuizType.practice:
        icon = Icons.psychology;
        color = Colors.blue;
        break;
      case QuizType.graded:
        icon = Icons.assignment;
        color = Colors.orange;
        break;
      case QuizType.diagnostic:
        icon = Icons.analytics;
        color = Colors.purple;
        break;
      case QuizType.final:
        icon = Icons.school;
        color = Colors.red;
        break;
      case QuizType.certification:
        icon = Icons.workspace_premium;
        color = const Color(0xFFFFD700);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusChip(QuizStatus status) {
    String label;
    Color color;
    IconData icon;

    switch (status) {
      case QuizStatus.pending:
        label = 'Pendiente';
        color = Colors.grey;
        icon = Icons.schedule;
        break;
      case QuizStatus.inProgress:
        label = 'En Progreso';
        color = Colors.orange;
        icon = Icons.play_circle_outline;
        break;
      case QuizStatus.completed:
        label = 'Completado';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    QuizModel quiz,
    QuizAttempt? lastAttempt,
    QuizStatus status,
    QuizEligibility eligibility,
  ) {
    String label;
    IconData icon;
    Color color;
    VoidCallback onPressed;

    if (lastAttempt != null && lastAttempt.status == QuizAttemptStatus.inProgress) {
      label = 'Continuar';
      icon = Icons.play_arrow;
      color = Colors.orange;
      onPressed = () => _resumeQuiz(quiz, lastAttempt);
    } else if (status == QuizStatus.completed && quiz.allowReview) {
      label = 'Ver Resultados';
      icon = Icons.visibility;
      color = Colors.blue;
      onPressed = () => _viewResults(quiz, lastAttempt!);
    } else {
      label = attempts.isEmpty ? 'Comenzar' : 'Reintentar';
      icon = Icons.play_arrow;
      color = const Color(0xFFCC0000);
      onPressed = () => _startQuiz(quiz);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  QuizStatus _getQuizStatus(QuizModel quiz, List<QuizAttempt> attempts) {
    if (attempts.isEmpty) {
      return QuizStatus.pending;
    }

    final lastAttempt = attempts.last;
    if (lastAttempt.status == QuizAttemptStatus.inProgress) {
      return QuizStatus.inProgress;
    }

    if (lastAttempt.passed || attempts.length >= quiz.maxAttempts) {
      return QuizStatus.completed;
    }

    return QuizStatus.pending;
  }

  QuizAttempt? _getBestAttempt(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return null;

    return attempts.reduce((best, current) {
      if (current.percentage > best.percentage) {
        return current;
      }
      return best;
    });
  }

  double _calculateProgress(QuizModel quiz, QuizAttempt attempt) {
    return attempt.answers.length / quiz.questions.length;
  }

  List<Map<String, dynamic>> _filterQuizzesByStatus(
    List<QuizModel> quizzes,
    QuizStatus status,
  ) {
    final List<Map<String, dynamic>> result = [];

    for (final quiz in quizzes) {
      final attemptsAsync = ref.watch(quizAttemptsProvider(quiz.id));

      attemptsAsync.whenData((attempts) {
        final quizStatus = _getQuizStatus(quiz, attempts);
        if (quizStatus == status) {
          result.add({
            'quiz': quiz,
            'attempts': attempts,
          });
        }
      });
    }

    return result;
  }

  void _handleQuizTap(
    QuizModel quiz,
    QuizEligibility? eligibility,
    QuizAttempt? lastAttempt,
  ) {
    if (eligibility?.canTake ?? false) {
      if (lastAttempt != null && lastAttempt.status == QuizAttemptStatus.inProgress) {
        _resumeQuiz(quiz, lastAttempt);
      } else {
        _showQuizDetails(quiz);
      }
    }
  }

  void _showQuizDetails(QuizModel quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuizDetailsSheet(
        quiz: quiz,
        onStart: () {
          Navigator.pop(context);
          _startQuiz(quiz);
        },
      ),
    );
  }

  void _startQuiz(QuizModel quiz) {
    context.push('/quiz/${quiz.id}');
  }

  void _resumeQuiz(QuizModel quiz, QuizAttempt attempt) {
    ref.read(currentQuizAttemptProvider.notifier).resumeQuiz(attempt.id);
    context.push('/quiz/${quiz.id}');
  }

  void _viewResults(QuizModel quiz, QuizAttempt attempt) {
    context.push('/quiz/${quiz.id}/results/${attempt.id}');
  }

  IconData _getEmptyStateIcon(QuizStatus status) {
    switch (status) {
      case QuizStatus.pending:
        return Icons.assignment_outlined;
      case QuizStatus.inProgress:
        return Icons.play_circle_outline;
      case QuizStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  String _getEmptyStateTitle(QuizStatus status) {
    switch (status) {
      case QuizStatus.pending:
        return 'No hay evaluaciones pendientes';
      case QuizStatus.inProgress:
        return 'No hay evaluaciones en progreso';
      case QuizStatus.completed:
        return 'No has completado evaluaciones';
    }
  }

  String _getEmptyStateMessage(QuizStatus status) {
    switch (status) {
      case QuizStatus.pending:
        return 'Explora los cursos para encontrar evaluaciones';
      case QuizStatus.inProgress:
        return 'Comienza una evaluación para verla aquí';
      case QuizStatus.completed:
        return 'Completa evaluaciones para ver tus resultados';
    }
  }
}

// Provider para obtener todos los quizzes del usuario
final _allUserQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  // Este provider debería implementarse para obtener todos los quizzes
  // disponibles para el usuario actual desde el servidor
  return [];
});

// Enumeración para el estado del quiz
enum QuizStatus {
  pending,
  inProgress,
  completed,
}

// Widget para mostrar detalles del quiz
class _QuizDetailsSheet extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onStart;

  const _QuizDetailsSheet({
    Key? key,
    required this.quiz,
    required this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (quiz.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      quiz.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.quiz,
                    'Preguntas',
                    '${quiz.questions.length}',
                  ),
                  _buildDetailRow(
                    Icons.timer,
                    'Tiempo límite',
                    quiz.formattedTimeLimit,
                  ),
                  _buildDetailRow(
                    Icons.grade,
                    'Puntaje para aprobar',
                    '${quiz.passingScore}%',
                  ),
                  _buildDetailRow(
                    Icons.repeat,
                    'Intentos permitidos',
                    quiz.maxAttempts == 0 ? 'Ilimitados' : '${quiz.maxAttempts}',
                  ),
                  _buildDetailRow(
                    Icons.star,
                    'Puntos totales',
                    '${quiz.totalPoints}',
                  ),
                  if (quiz.shuffleQuestions)
                    _buildDetailRow(
                      Icons.shuffle,
                      'Orden de preguntas',
                      'Aleatorio',
                    ),
                  if (quiz.showCorrectAnswers)
                    _buildDetailRow(
                      Icons.visibility,
                      'Respuestas correctas',
                      'Se muestran al finalizar',
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Comenzar Evaluación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}