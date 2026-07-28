import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/feedback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyPortfolioApp());
}

class MyPortfolioApp extends StatelessWidget {
  const MyPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portfolio App2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090B12),
        splashFactory: InkRipple.splashFactory,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5AF5B4),
          secondary: Color(0xFF4D9DFF),
          surface: Color(0xFF111827),
          surfaceTint: Color(0xFF070A13),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          elevation: 6,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF131A2B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white60),
        ),
      ),
      home: const PortfolioHomePage(),
    );
  }
}

class PortfolioHomePage extends StatefulWidget {
  const PortfolioHomePage({super.key});

  @override
  State<PortfolioHomePage> createState() => _PortfolioHomePageState();
}

class _PortfolioHomePageState extends State<PortfolioHomePage> {
  final projects = [
    {
      'name': 'Portfolio Website',
      'description':
          'A clean personal portfolio app built with Flutter UI widgets.',
    },
    {
      'name': 'Flutter Quiz App',
      'description':
          'A quiz app that shows how to organize simple stateful logic.',
    },
    {
      'name': 'Weather App',
      'description':
          'A weather app concept that demonstrates API-driven UI design.',
    },
  ];

  final socialLinks = [
    {'label': 'GitHub', 'icon': Icons.code, 'url': 'https://github.com'},
    {
      'label': 'LinkedIn',
      'icon': Icons.business_center,
      'url': 'https://www.linkedin.com',
    },
    {
      'label': 'Instagram',
      'icon': Icons.camera_alt,
      'url': 'https://www.instagram.com',
    },
    {'label': 'X / Twitter', 'icon': Icons.chat, 'url': 'https://x.com'},
  ];

  String selectedProject = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FeedbackService feedbackService = FeedbackService(
    Supabase.instance.client,
  );
  bool isSubmitting = false;
  bool isLoadingFeedback = false;
  String feedbackMessage = '';
  List<Map<String, dynamic>> recentFeedbacks = [];

  @override
  void initState() {
    super.initState();
    loadRecentFeedback();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitFeedback() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || phone.isEmpty || description.isEmpty) {
      setState(() {
        feedbackMessage = 'Please fill in all fields.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      feedbackMessage = '';
    });

    try {
      await feedbackService.createFeedback(
        name: name,
        phone: phone,
        description: description,
      );

      if (!mounted) return;

      setState(() {
        feedbackMessage = 'Feedback sent successfully!';
        nameController.clear();
        phoneController.clear();
        descriptionController.clear();
      });

      await loadRecentFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        feedbackMessage = 'Failed to send feedback: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  } // End of submitFeedback

  Future<void> loadRecentFeedback() async {
    if (!feedbackService.isReady) {
      setState(() {
        recentFeedbacks = [];
      });
      return;
    }

    setState(() {
      isLoadingFeedback = true;
    });

    try {
      final feedbacks = await feedbackService.fetchFeedback(limit: 10);
      if (!mounted) return;
      setState(() {
        recentFeedbacks = feedbacks;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recentFeedbacks = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to load feedback: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFeedback = false;
        });
      }
    }
  } // End of loadRecentFeedback

  Future<void> deleteFeedbackItem(String id) async {
    try {
      await feedbackService.deleteFeedback(id);
      await loadRecentFeedback();
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Feedback deleted')));
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  } // End of deleteFeedbackItem

  Future<void> editFeedbackItem(Map<String, dynamic> feedback) async {
    final id = feedback['id']?.toString();
    if (id == null || id.isEmpty) return;

    final nameController = TextEditingController(
      text: feedback['name']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: feedback['phone']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: feedback['description']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text.trim();
                final updatedPhone = phoneController.text.trim();
                final updatedDescription = descriptionController.text.trim();

                if (updatedName.isEmpty ||
                    updatedPhone.isEmpty ||
                    updatedDescription.isEmpty) {
                  return;
                }

                try {
                  await feedbackService.updateFeedback(
                    id: id,
                    name: updatedName,
                    phone: updatedPhone,
                    description: updatedDescription,
                  );
                  if (!mounted) return;
                  await loadRecentFeedback();
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback updated')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
  } // End of editFeedbackItem

  @override
  Widget build(BuildContext context) {
    final gradientBackground = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF070A13), Color(0xFF121931)],
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Portfolio'),
      ),
      body: Container(
        decoration: gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF111827), Color(0xFF17233C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          const BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.35),
                            blurRadius: 26,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5AF5B4), Color(0xFF4D9DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 68,
                              backgroundColor: const Color(0xFF070A13),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/profile.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Prajwal',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Flutter Developer • UI Enthusiast',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                buildSectionTitle('About Me'),
                const SizedBox(height: 10),
                buildInfoCard(
                  const Text(
                    'I love building beautiful mobile apps that feel smooth, bold, and simple. '
                    'This portfolio blends animation, custom buttons, and modern card styles so visitors can explore projects quickly.',
                  ),
                ),
                const SizedBox(height: 24),
                buildSectionTitle('Projects'),
                const SizedBox(height: 12),
                ...projects.map((project) {
                  final projectName = project['name'] as String;
                  final description = project['description'] as String;
                  final isSelected = selectedProject == projectName;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF1C2B52), Color(0xFF0E142A)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF111827)],
                              ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5AF5B4)
                              : Colors.white12,
                          width: 1.4,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedProject = isSelected ? '' : projectName;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          projectName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons
                                                  .keyboard_double_arrow_up_rounded
                                            : Icons
                                                  .keyboard_double_arrow_down_rounded,
                                        color: isSelected
                                            ? const Color(0xFF5AF5B4)
                                            : Colors.white54,
                                      ),
                                    ],
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: ConstrainedBox(
                                      constraints: isSelected
                                          ? const BoxConstraints()
                                          : const BoxConstraints(maxHeight: 0),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 14),
                                        child: Text(
                                          description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                buildSectionTitle('Leave Feedback'),
                const SizedBox(height: 12),
                buildInfoCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Your feedback',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitFeedback,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 22,
                            ),
                            backgroundColor: const Color(0xFF5AF5B4),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            isSubmitting ? 'Sending...' : 'Send Feedback',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: feedbackMessage.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                feedbackMessage,
                                key: ValueKey(feedbackMessage),
                                style: TextStyle(
                                  color:
                                      feedbackMessage.contains('successfully')
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                buildSectionTitle('Recent Feedback'),
                const SizedBox(height: 12),
                if (isLoadingFeedback)
                  const Center(child: CircularProgressIndicator())
                else if (recentFeedbacks.isEmpty)
                  buildInfoCard(
                    const Text(
                      'No feedback yet. Be the first to share a message!',
                    ),
                  )
                else
                  Column(
                    children: recentFeedbacks.map((feedback) {
                      final id = feedback['id']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildFeedbackTile(
                          feedback,
                          onEdit: () => editFeedbackItem(feedback),
                          onDelete: id.isNotEmpty
                              ? () => deleteFeedbackItem(id)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                buildSectionTitle('Social Media'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: socialLinks.map((link) {
                    return SocialLinkChip(
                      icon: link['icon'] as IconData,
                      label: link['label'] as String,
                      url: link['url'] as String,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget buildInfoCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(17, 24, 39, 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildFeedbackTile(
    Map<String, dynamic> feedback, {
    required VoidCallback onEdit,
    required VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feedback['name']?.toString() ?? 'No name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feedback['description']?.toString() ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  backgroundColor: const Color(0xFF17233C),
                  label: Text(
                    feedback['phone']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF5AF5B4)),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLinkChip extends StatelessWidget {
  const SocialLinkChip({
    super.key,
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
