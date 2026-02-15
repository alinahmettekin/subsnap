import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/support_service.dart';

class HelpAndSupportView extends ConsumerStatefulWidget {
  const HelpAndSupportView({super.key});

  @override
  ConsumerState<HelpAndSupportView> createState() => _HelpAndSupportViewState();
}

class _HelpAndSupportViewState extends ConsumerState<HelpAndSupportView> {
  final _serviceFormKey = GlobalKey<FormState>();
  final _feedbackFormKey = GlobalKey<FormState>();

  final _serviceNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _feedbackController = TextEditingController();

  // Track expanded section for accordion behavior
  String? _expandedSectionId;

  bool _isServiceLoading = false;
  bool _isFeedbackLoading = false;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDescController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitServiceRequest() async {
    if (!_serviceFormKey.currentState!.validate()) return;

    setState(() => _isServiceLoading = true);
    try {
      await ref
          .read(supportServiceProvider)
          .submitServiceRequest(_serviceNameController.text.trim(), _serviceDescController.text.trim());

      if (mounted) {
        _serviceNameController.clear();
        _serviceDescController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servis ekleme isteğiniz alındı! Teşekkür ederiz.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isServiceLoading = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;

    setState(() => _isFeedbackLoading = true);
    try {
      await ref.read(supportServiceProvider).submitFeedback(_feedbackController.text.trim());

      if (mounted) {
        _feedbackController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri bildiriminiz için teşekkürler!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isFeedbackLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Yardım ve Destek'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sıkça Sorulan Sorular', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFAQItem(
              'faq1',
              'Nasıl abonelik eklerim?',
              'Anasayfadaki "+" butonuna tıklayarak yeni bir abonelik ekleyebilirsiniz. Listede servisinizi bulamazsanız "Diğer" kategorisini seçebilir veya aşağıdan bize istek gönderebilirsiniz.',
            ),
            _buildFAQItem(
              'faq2',
              'Ödemelerim neden görünmüyor?',
              'Ödemeleriniz, abonelik tarihine göre otomatik hesaplanır. Eğer manuel bir ödeme yaptıysanız "Ödemeler" sayfasından ekleyebilirsiniz.',
            ),
            _buildFAQItem(
              'faq3',
              'Premium özellikler nelerdir?',
              'Sınırsız kart ekleme, detaylı harcama analizleri ve bulut senkronizasyonu gibi özellikler Premium paketimizde mevcuttur.',
            ),
            const SizedBox(height: 32),
            Text('İstek ve Öneriler', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildServiceRequestForm('service_request', theme),
            const SizedBox(height: 16),
            _buildFeedbackForm('feedback', theme),
            const SizedBox(height: 32),
            Center(
              child: Text('SubSnap v1.0.0', style: textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String id, String question, String answer) {
    final isExpanded = _expandedSectionId == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: Key('faq_${id}_$isExpanded'), // Force rebuild state on change
        initiallyExpanded: isExpanded,
        onExpansionChanged: (isOpen) {
          if (isOpen) {
            setState(() => _expandedSectionId = id);
          } else if (_expandedSectionId == id) {
            setState(() => _expandedSectionId = null);
          }
        },
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [Padding(padding: const EdgeInsets.all(16.0), child: Text(answer))],
      ),
    );
  }

  Widget _buildServiceRequestForm(String id, ThemeData theme) {
    final isExpanded = _expandedSectionId == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: Key('service_${id}_$isExpanded'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (isOpen) {
          if (isOpen) {
            setState(() => _expandedSectionId = id);
          } else if (_expandedSectionId == id) {
            setState(() => _expandedSectionId = null);
          }
        },
        leading: const FaIcon(FontAwesomeIcons.plus, size: 20),
        title: const Text('Listede Olmayan Servis Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Eksik bir servis mi var?', style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _serviceFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _serviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Servis Adı',
                      hintText: 'Örn: BluTV, Exxen...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serviceDescController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (Opsiyonel)',
                      hintText: 'Web sitesi linki vb.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isServiceLoading ? null : _submitServiceRequest,
                    icon: _isServiceLoading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: const Text('İstek Gönder'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm(String id, ThemeData theme) {
    final isExpanded = _expandedSectionId == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: Key('feedback_${id}_$isExpanded'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (isOpen) {
          if (isOpen) {
            setState(() => _expandedSectionId = id);
          } else if (_expandedSectionId == id) {
            setState(() => _expandedSectionId = null);
          }
        },
        leading: const FaIcon(FontAwesomeIcons.solidCommentDots, size: 20),
        title: const Text('Geri Bildirim / Öneri', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Fikirlerinizi bizimle paylaşın', style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _feedbackFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _feedbackController,
                    decoration: const InputDecoration(
                      labelText: 'Mesajınız',
                      hintText: 'Uygulamayı geliştirmemize yardımcı olun...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty == true ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isFeedbackLoading ? null : _submitFeedback,
                    icon: _isFeedbackLoading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: const Text('Gönder'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
