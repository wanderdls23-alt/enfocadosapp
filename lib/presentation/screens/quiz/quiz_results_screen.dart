import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:confetti/confetti.dart';

import '../../../data/models/quiz_model.dart';
import '../../../data/models/certificate_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/certificate_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';

class QuizResultsScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String attemptId;

  const QuizResultsScreen({
    Key? key,
    required this.quizId,
    required this.attemptId,
  }) : super(key: key);

  @override
  ConsumerState<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends ConsumerState<QuizResultsScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));
    final attemptAsync = ref.watch(
      ref.watch(quizRepositoryProvider).getAttempt(widget.attemptId).asStream().asBroadcastStream().first.asStream().asBroadcastStream().first,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Resultados del Quiz'),
        backgroundColor: const Color(0xFFCC0000),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/academy'),
        ),
      ),
      body: FutureBuilder<QuizAttempt?>(
        future: ref.read(quizRepositoryProvider).getAttempt(widget.attemptId),
        builder: (context, attemptSnapshot) {
          if (!attemptSnapshot.hasData) {
            return const Center(child: LoadingWidget());
          }

          final attempt = attemptSnapshot.data!;

          return quizAsync.when(
            data: (quiz) {
              // Mostrar confeti si aprobó
              if (attempt.passed && !_confettiController.state.isPlaying) {
                _confettiController.play();
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Encabezado con resultados
                        _buildResultsHeader(quiz, attempt),

                        // Estadísticas
                        _buildStatistics(quiz, attempt),

                        // Botones de acción
                        _buildActionButtons(quiz, attempt),

                        // Detalles de respuestas (expandible)
                        if (_showDetails) _buildAnswerDetails(quiz, attempt),
                      ],
                    ),
                  ),

                  // Confeti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: 3.14 / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 50,
                      gravity: 0.1,
                      colors: const [
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple,
                        Color(0xFFFFD700),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: LoadingWidget()),
            error: (error, _) => Center(
              child: Text('Error: $error'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(QuizModel quiz, QuizAttempt attempt) {
    final isPassed = attempt.passed;
    final color = isPassed ? Colors.green : Colors.red;
    final icon = isPassed ? Icons.check_circle : Icons.cancel;
    final message = isPassed ? '¡Felicitaciones!' : 'Sigue intentando';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 12.0,
                  animation: true,
                  animationDuration: 1500,
                  percent: attempt.percentage / 100,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${attempt.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed
                ? 'Has aprobado el quiz'
                : 'Necesitas ${quiz.passingScore}% para aprobar',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(QuizModel quiz, QuizAttempt attempt) {
    final correctAnswers = _calculateCorrectAnswers(quiz, attempt);
    final totalQuestions = quiz.questions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                icon: Icons.check,
                label: 'Respuestas Correctas',
                value: '$correctAnswers de $totalQuestions',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.timer,
                label: 'Tiempo',
                value: attempt.formattedTimeTaken,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.score,
                label: 'Puntaje',
                value: '${attempt.score.toStringAsFixed(1)} / ${quiz.totalPoints}',
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.repeat,
                label: 'Intento',
                value: '#${attempt.attemptNumber}',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(QuizModel quiz, QuizAttempt attempt) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botón de ver detalles
          CustomButton(
            text: _showDetails ? 'Ocultar Detalles' : 'Ver Detalles',
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            icon: _showDetails ? Icons.expand_less : Icons.expand_more,
            backgroundColor: Colors.grey[600]!,
          ),
          const SizedBox(height: 12),

          // Botón de reintentar (si no aprobó y tiene intentos)
          if (!attempt.passed && quiz.maxAttempts > attempt.attemptNumber) ...[
            CustomButton(
              text: 'Reintentar Quiz',
              onPressed: () => context.pushReplacement('/quiz/${widget.quizId}'),
              icon: Icons.refresh,
              backgroundColor: Colors.orange,
            ),
            const SizedBox(height: 12),
          ],

          // Botón de certificado (si aprobó y es quiz de certificación)
          if (attempt.passed && quiz.type == QuizType.certification) ...[
            CustomButton(
              text: 'Obtener Certificado',
              onPressed: () => _requestCertificate(quiz),
              icon: Icons.workspace_premium,
              backgroundColor: const Color(0xFFFFD700),
              textColor: Colors.black,
            ),
            const SizedBox(height: 12),
          ],

          // Botón de continuar
          CustomButton(
            text: 'Continuar',
            onPressed: () => context.go('/academy'),
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerDetails(QuizModel quiz, QuizAttempt attempt) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revisión de Respuestas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...quiz.questions.map((question) {
            final userAnswers = attempt.answers[question.id] ?? [];
            final isCorrect = question.isAnswerCorrect(userAnswers);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Respuesta del usuario
                  if (userAnswers.isNotEmpty) ...[
                    Text(
                      'Tu respuesta:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    ...userAnswers.map((answerId) {
                      final answer = question.answers.firstWhere(
                        (a) => a.id == answerId,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          '• ${answer.text}',
                          style: TextStyle(
                            color: answer.isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    Text(
                      'Sin respuesta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Respuesta correcta (si se muestra y el usuario falló)
                  if (quiz.showCorrectAnswers && !isCorrect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Respuesta correcta:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    ...question.correctAnswers.map((answer) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          '• ${answer.text}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],

                  // Explicación (si está disponible)
                  if (question.explanation != null && quiz.showCorrectAnswers) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.explanation!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int _calculateCorrectAnswers(QuizModel quiz, QuizAttempt attempt) {
    int correct = 0;
    for (final question in quiz.questions) {
      final userAnswers = attempt.answers[question.id] ?? [];
      if (question.isAnswerCorrect(userAnswers)) {
        correct++;
      }
    }
    return correct;
  }

  Future<void> _requestCertificate(QuizModel quiz) async {
    try {
      final request = CertificateRequest(
        courseId: quiz.courseId,
        customData: {
          'quizId': quiz.id,
          'attemptId': widget.attemptId,
        },
      );

      await ref.read(certificateRequestProvider.notifier).requestCertificate(request);

      final certificateState = ref.read(certificateRequestProvider);
      if (certificateState is AsyncData && certificateState.value != null) {
        // Navegar al certificado
        context.push('/certificate/${certificateState.value!.id}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar certificado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}