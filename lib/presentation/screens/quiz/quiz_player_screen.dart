import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';

class QuizPlayerScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizPlayerScreen({
    Key? key,
    required this.quizId,
  }) : super(key: key);

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  PageController? _pageController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Iniciar el quiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuiz();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    await ref.read(currentQuizAttemptProvider.notifier).startQuiz(widget.quizId);

    final quiz = await ref.read(quizProvider(widget.quizId).future);
    if (quiz.timeLimit > 0) {
      ref.read(quizTimerProvider.notifier).startTimer(
        timeLimitMinutes: quiz.timeLimit,
      );
    } else {
      ref.read(quizTimerProvider.notifier).startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));
    final attemptAsync = ref.watch(currentQuizAttemptProvider);
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final elapsedTime = ref.watch(quizTimerProvider);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmation();
        if (shouldExit) {
          await ref.read(currentQuizAttemptProvider.notifier).pauseQuiz();
        }
        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: quizAsync.when(
            data: (quiz) => Text(quiz.title),
            loading: () => const Text('Cargando...'),
            error: (_, __) => const Text('Quiz'),
          ),
          backgroundColor: const Color(0xFFCC0000),
          actions: [
            // Temporizador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: quizAsync.when(
                  data: (quiz) {
                    final formattedTime = ref.read(quizTimerProvider.notifier).formattedTime;
                    final isTimeLimited = quiz.timeLimit > 0;
                    final remainingTime = isTimeLimited
                        ? Duration(minutes: quiz.timeLimit) - elapsedTime
                        : null;

                    return Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: remainingTime != null && remainingTime.inMinutes < 5
                              ? Colors.orange
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTimeLimited && remainingTime != null
                              ? '${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}'
                              : formattedTime,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: remainingTime != null && remainingTime.inMinutes < 5
                                ? Colors.orange
                                : Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),
          ],
        ),
        body: quizAsync.when(
          data: (quiz) {
            return attemptAsync.when(
              data: (attempt) {
                if (attempt == null) {
                  return const Center(child: LoadingWidget());
                }

                return Column(
                  children: [
                    // Barra de progreso
                    _buildProgressBar(quiz, currentIndex),

                    // Contenido del quiz
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          ref.read(currentQuestionIndexProvider.notifier).state = index;
                        },
                        itemCount: quiz.questions.length,
                        itemBuilder: (context, index) {
                          final question = quiz.questions[index];
                          return _buildQuestionPage(quiz, question, index);
                        },
                      ),
                    ),

                    // Navegación
                    _buildNavigationBar(quiz, currentIndex),
                  ],
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
                      onPressed: _startQuiz,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: LoadingWidget()),
          error: (error, _) => Center(
            child: Text('Error al cargar quiz: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(QuizModel quiz, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${currentIndex + 1} de ${quiz.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_calculateAnsweredQuestions()} respondidas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentIndex + 1) / quiz.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Color(0xFFCC0000)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(QuizModel quiz, QuizQuestion question, int index) {
    final selectedAnswers = ref.watch(selectedAnswersProvider(question.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pregunta
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC0000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${question.points} punto${question.points != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (question.bibleReference != null)
                        Chip(
                          label: Text(
                            question.bibleReference!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (question.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: question.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Respuestas
          _buildAnswerOptions(question, selectedAnswers),

          // Pistas (si están disponibles)
          if (question.hints != null && question.hints!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHintSection(question),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question, List<String> selectedAnswers) {
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        return Column(
          children: question.answers.map((answer) {
            final isSelected = selectedAnswers.contains(answer.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _selectAnswer(question, answer.id, false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFCC0000).withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFCC0000)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFCC0000)
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFFCC0000)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          answer.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case QuestionType.multipleChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Selecciona todas las correctas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...question.answers.map((answer) {
              final isSelected = selectedAnswers.contains(answer.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _selectAnswer(question, answer.id, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFCC0000).withOpacity(0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFCC0000)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFCC0000)
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected
                                ? const Color(0xFFCC0000)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            answer.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );

      default:
        return const Text('Tipo de pregunta no soportado');
    }
  }

  Widget _buildHintSection(QuizQuestion question) {
    final usedHints = ref.watch(usedHintsProvider);
    final hintLevel = usedHints.getHintLevel(question.id);
    final maxHints = question.hints?.length ?? 0;

    if (hintLevel >= maxHints) {
      return const SizedBox();
    }

    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hintLevel == 0) ...[
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    '¿Necesitas ayuda?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _useHint(question.id),
                    child: const Text('Ver pista'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Pista $hintLevel de $maxHints',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.hints![hintLevel - 1].toString()),
              if (hintLevel < maxHints) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _useHint(question.id),
                  child: const Text('Siguiente pista'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(QuizModel quiz, int currentIndex) {
    final isLastQuestion = currentIndex == quiz.questions.length - 1;
    final hasAnswered = _hasAnsweredCurrentQuestion(quiz.questions[currentIndex]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: CustomButton(
                text: 'Anterior',
                onPressed: () => _navigateToPrevious(),
                backgroundColor: Colors.grey[600]!,
              ),
            ),
          if (currentIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isLastQuestion ? 'Finalizar Quiz' : 'Siguiente',
              onPressed: hasAnswered || !isLastQuestion
                  ? () => isLastQuestion ? _submitQuiz() : _navigateToNext()
                  : null,
              icon: isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
              backgroundColor: isLastQuestion
                  ? Colors.green
                  : const Color(0xFFCC0000),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(QuizQuestion question, String answerId, bool isMultiple) {
    final currentAnswers = ref.read(selectedAnswersProvider(question.id));

    List<String> updatedAnswers;
    if (isMultiple) {
      if (currentAnswers.contains(answerId)) {
        updatedAnswers = currentAnswers.where((id) => id != answerId).toList();
      } else {
        updatedAnswers = [...currentAnswers, answerId];
      }
    } else {
      updatedAnswers = [answerId];
    }

    ref.read(selectedAnswersProvider(question.id).notifier).state = updatedAnswers;

    // Guardar respuesta en el intento
    ref.read(currentQuizAttemptProvider.notifier).submitAnswer(
      questionId: question.id,
      answerIds: updatedAnswers,
    );
  }

  void _useHint(String questionId) {
    ref.read(usedHintsProvider.notifier).useHint(questionId);
  }

  bool _hasAnsweredCurrentQuestion(QuizQuestion question) {
    final answers = ref.read(selectedAnswersProvider(question.id));
    return answers.isNotEmpty;
  }

  int _calculateAnsweredQuestions() {
    final attemptState = ref.read(currentQuizAttemptProvider);
    if (attemptState is AsyncData<QuizAttempt?> && attemptState.value != null) {
      return attemptState.value!.answers.length;
    }
    return 0;
  }

  void _navigateToPrevious() {
    _pageController?.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToNext() {
    _pageController?.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Quiz'),
        content: Text(
          '¿Estás seguro de que quieres enviar tus respuestas?\n\n'
          'Has respondido $_calculateAnsweredQuestions() preguntas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (shouldSubmit ?? false) {
      setState(() => _isSubmitting = true);

      ref.read(quizTimerProvider.notifier).stopTimer();
      final completedAttempt = await ref
          .read(currentQuizAttemptProvider.notifier)
          .completeQuiz();

      if (completedAttempt != null) {
        // Navegar a la pantalla de resultados
        context.pushReplacement('/quiz/${widget.quizId}/results/${completedAttempt.id}');
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar el quiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del quiz?'),
        content: const Text(
          'Tu progreso se guardará y podrás continuar más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    ) ?? false;
  }
}