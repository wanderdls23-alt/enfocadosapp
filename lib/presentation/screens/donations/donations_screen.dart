import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donations_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class DonationsScreen extends ConsumerStatefulWidget {
  const DonationsScreen({super.key});

  @override
  ConsumerState<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends ConsumerState<DonationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _customAmountController = TextEditingController();

  String _selectedFrequency = 'once'; // once, monthly, yearly
  double _selectedAmount = 0;
  String _selectedPaymentMethod = '';
  bool _isAnonymous = false;
  bool _includeMessage = false;
  final _messageController = TextEditingController();

  final List<double> _quickAmounts = [10, 25, 50, 100, 250, 500];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAmountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.user;
    final donationStats = ref.watch(donationStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.gold.shade700,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        const Text(
                          'Apoya Nuestro Ministerio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Scripture
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '"Cada uno dé como propuso en su corazón: no con tristeza, ni por necesidad, porque Dios ama al dador alegre."',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '2 Corintios 9:7',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Donaciones',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () => context.push(Routes.donationHistory),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Impact Stats
                  donationStats.when(
                    data: (stats) => _buildImpactStats(stats),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Donation Type Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: const [
                            Tab(text: 'General'),
                            Tab(text: 'Proyectos'),
                            Tab(text: 'Diezmos'),
                          ],
                        ),
                        SizedBox(
                          height: 600,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildGeneralDonation(),
                              _buildProjectsDonation(),
                              _buildTitheDonation(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods
                  _buildPaymentMethods(),

                  const SizedBox(height: 24),

                  // Additional Options
                  _buildAdditionalOptions(),

                  const SizedBox(height: 32),

                  // Donate Button
                  _buildDonateButton(),

                  const SizedBox(height: 24),

                  // Security Info
                  _buildSecurityInfo(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStats(DonationStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.gold.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu Impacto',
                style: TextStyle(
                  color: AppColors.gold.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: stats.totalRaised.toStringAsFixed(0),
                label: 'Recaudado',
                prefix: '\$',
              ),
              _StatItem(
                value: stats.totalDonors.toString(),
                label: 'Donantes',
                icon: Icons.people,
              ),
              _StatItem(
                value: stats.projectsSupported.toString(),
                label: 'Proyectos',
                icon: Icons.work,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralDonation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Tu donación ayuda a mantener nuestro ministerio y expandir el Reino de Dios.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Frequency Selection
          _buildFrequencySelector(),
          const SizedBox(height: 24),

          // Amount Selection
          _buildAmountSelector(),
          const SizedBox(height: 24),

          // What your donation does
          _buildImpactInfo(),
        ],
      ),
    );
  }

  Widget _buildProjectsDonation() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProjectCard(
          title: 'Construcción del Nuevo Templo',
          description: 'Ayúdanos a construir un espacio más grande para adorar.',
          goal: 100000,
          raised: 45000,
          image: 'assets/images/temple.jpg',
        ),
        const SizedBox(height: 16),
        _ProjectCard(
          title: 'Misión Honduras 2024',
          description: 'Llevando el evangelio y ayuda humanitaria.',
          goal: 25000,
          raised: 18500,
          image: 'assets/images/mission.jpg',
        ),
        const SizedBox(height: 16),
        _ProjectCard(
          title: 'Equipamiento de Transmisión',
          description: 'Mejorando nuestra calidad de transmisión en línea.',
          goal: 15000,
          raised: 8000,
          image: 'assets/images/broadcast.jpg',
        ),
      ],
    );
  }

  Widget _buildTitheDonation() {
    final user = ref.watch(authStateProvider).value?.user;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Biblical Reference
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  '"Traed todos los diezmos al alfolí y haya alimento en mi casa; y probadme ahora en esto, dice Jehová de los ejércitos, si no os abriré las ventanas de los cielos, y derramaré sobre vosotros bendición hasta que sobreabunde."',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Malaquías 3:10',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tithe Calculator
          const Text(
            'Calculadora de Diezmo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Ingreso mensual',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: _calculateTithe,
              ),
            ),
            onChanged: (value) {
              _calculateTithe();
            },
          ),
          const SizedBox(height: 16),

          // Calculated Tithe
          if (_customAmountController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tu diezmo (10%):',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '\$${_calculateTitheAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Recurring Setup
          if (user != null) ...[
            SwitchListTile(
              value: _selectedFrequency == 'monthly',
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value ? 'monthly' : 'once';
                });
              },
              title: const Text('Configurar diezmo mensual automático'),
              subtitle: Text(
                'Se debitará automáticamente cada mes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              activeColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final frequencies = [
      {'id': 'once', 'label': 'Una vez', 'icon': Icons.looks_one},
      {'id': 'monthly', 'label': 'Mensual', 'icon': Icons.calendar_month},
      {'id': 'yearly', 'label': 'Anual', 'icon': Icons.calendar_today},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frecuencia de donación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: frequencies.map((freq) {
            final isSelected = _selectedFrequency == freq['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFrequency = freq['id'] as String;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        freq['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        freq['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el monto',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _quickAmounts.length + 1,
          itemBuilder: (context, index) {
            if (index < _quickAmounts.length) {
              final amount = _quickAmounts[index];
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _customAmountController.clear();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '\$${amount.toInt()}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            } else {
              // Custom amount
              return Container(
                decoration: BoxDecoration(
                  color: _selectedAmount == -1
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedAmount == -1
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Otro',
                    style: TextStyle(
                      color: _selectedAmount == -1
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: _selectedAmount == -1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }
          },
        ),
        if (_selectedAmount == -1) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Monto personalizado',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImpactInfo() {
    final impacts = [
      {'amount': 10, 'impact': 'Provee materiales para una clase de escuela dominical'},
      {'amount': 25, 'impact': 'Alimenta a una familia necesitada por una semana'},
      {'amount': 50, 'impact': 'Cubre costos de transmisión en vivo por un día'},
      {'amount': 100, 'impact': 'Apoya a un misionero por una semana'},
      {'amount': 250, 'impact': 'Equipa completamente un aula de academia bíblica'},
      {'amount': 500, 'impact': 'Financia un evento evangelístico completo'},
    ];

    final selectedImpact = impacts.firstWhere(
      (impact) => _selectedAmount <= (impact['amount'] as int),
      orElse: () => impacts.last,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu donación de \$${_getSelectedAmountValue().toInt()}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedImpact['impact'] as String,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {'id': 'card', 'name': 'Tarjeta de Crédito/Débito', 'icon': Icons.credit_card},
      {'id': 'paypal', 'name': 'PayPal', 'icon': Icons.account_balance_wallet},
      {'id': 'bank', 'name': 'Transferencia Bancaria', 'icon': Icons.account_balance},
      {'id': 'crypto', 'name': 'Criptomonedas', 'icon': Icons.currency_bitcoin},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Método de pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...methods.map((method) {
            final isSelected = _selectedPaymentMethod == method['id'];
            return RadioListTile<String>(
              value: method['id'] as String,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: Text(method['name'] as String),
              secondary: Icon(
                method['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              activeColor: AppColors.primary,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opciones adicionales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value!;
              });
            },
            title: const Text('Donación anónima'),
            subtitle: Text(
              'Tu nombre no aparecerá en la lista de donantes',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            activeColor: AppColors.primary,
          ),
          CheckboxListTile(
            value: _includeMessage,
            onChanged: (value) {
              setState(() {
                _includeMessage = value!;
              });
            },
            title: const Text('Incluir mensaje'),
            subtitle: Text(
              'Agrega una nota o petición de oración',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            activeColor: AppColors.primary,
          ),
          if (_includeMessage) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje o petición...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    final amount = _getSelectedAmountValue();
    final isValid = amount > 0 && _selectedPaymentMethod.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid ? _processDonation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite),
            const SizedBox(width: 8),
            Text(
              'Donar \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedFrequency != 'once') ...[
              const SizedBox(width: 4),
              Text(
                _selectedFrequency == 'monthly' ? '/mes' : '/año',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donación 100% Segura',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tu información está protegida con encriptación SSL de 256 bits',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getSelectedAmountValue() {
    if (_selectedAmount == -1) {
      return double.tryParse(_customAmountController.text) ?? 0;
    }
    return _selectedAmount;
  }

  double _calculateTitheAmount() {
    final income = double.tryParse(_customAmountController.text) ?? 0;
    return income * 0.1;
  }

  void _calculateTithe() {
    if (_customAmountController.text.isNotEmpty) {
      setState(() {
        _selectedAmount = _calculateTitheAmount();
      });
    }
  }

  void _processDonation() {
    final amount = _getSelectedAmountValue();

    // Validate user is logged in
    final user = ref.read(authStateProvider).value?.user;
    if (user == null && !_isAnonymous) {
      // Prompt login
      context.push(Routes.login);
      return;
    }

    // Process payment based on method
    switch (_selectedPaymentMethod) {
      case 'card':
        _processCardPayment(amount);
        break;
      case 'paypal':
        _processPayPalPayment(amount);
        break;
      case 'bank':
        _showBankTransferInfo(amount);
        break;
      case 'crypto':
        _processCryptoPayment(amount);
        break;
    }
  }

  void _processCardPayment(double amount) {
    context.push(
      Routes.paymentCard,
      extra: {
        'amount': amount,
        'frequency': _selectedFrequency,
        'isAnonymous': _isAnonymous,
        'message': _includeMessage ? _messageController.text : null,
      },
    );
  }

  void _processPayPalPayment(double amount) {
    // Implement PayPal payment
  }

  void _showBankTransferInfo(double amount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información para Transferencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _BankInfoRow(label: 'Banco:', value: 'Banco Nacional'),
              _BankInfoRow(label: 'Cuenta:', value: '1234567890'),
              _BankInfoRow(label: 'Titular:', value: 'Iglesia Enfocados en Dios'),
              _BankInfoRow(label: 'Monto:', value: '\$${amount.toStringAsFixed(2)}'),
              _BankInfoRow(label: 'Referencia:', value: 'DON-${DateTime.now().millisecondsSinceEpoch}'),
              const SizedBox(height: 20),
              const Text(
                'Envía tu comprobante a: donaciones@enfocadosendiostv.com',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Copy to clipboard
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Información copiada al portapapeles'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar info'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _processCryptoPayment(double amount) {
    // Implement crypto payment
  }
}

// Supporting Widgets
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final String? prefix;
  final IconData? icon;

  const _StatItem({
    required this.value,
    required this.label,
    this.prefix,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.gold.shade700, size: 20),
              const SizedBox(width: 4),
            ],
            if (prefix != null)
              Text(
                prefix!,
                style: TextStyle(
                  color: AppColors.gold.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.gold.shade700,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final double goal;
  final double raised;
  final String image;

  const _ProjectCard({
    required this.title,
    required this.description,
    required this.goal,
    required this.raised,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final progress = raised / goal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                color: AppColors.textSecondary,
                size: 50,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${raised.toStringAsFixed(0)} recaudados',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Meta: \$${goal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Select project
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apoyar proyecto'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Donation Stats Model
class DonationStats {
  final double totalRaised;
  final int totalDonors;
  final int projectsSupported;

  DonationStats({
    required this.totalRaised,
    required this.totalDonors,
    required this.projectsSupported,
  });
}