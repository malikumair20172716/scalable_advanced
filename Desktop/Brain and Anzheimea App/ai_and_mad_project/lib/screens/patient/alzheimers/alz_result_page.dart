import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_and_mad_project/components/primary_button.dart';
import 'package:ai_and_mad_project/providers/theme_provider.dart';
import 'package:ai_and_mad_project/utils/app_routes.dart';

class AlzResultPage extends StatelessWidget {
  const AlzResultPage({super.key});

  // Map class codes to risk levels, colors, and descriptions
  static Map<String, dynamic> getClassInfo(String classCode) {
    final classMap = {
      'non_demented': {
        'riskLevel': 'No Signs of Dementia',
        'riskColor': Colors.green,
        'icon': Icons.check_circle,
        'description': 'Brain scan shows normal cognitive function',
      },
      'very_mild_demented': {
        'riskLevel': 'Very Mild Dementia',
        'riskColor': Colors.yellow,
        'icon': Icons.info_outline,
        'description': 'Very mild cognitive decline detected. Monitor regularly.',
      },
      'mild_demented': {
        'riskLevel': 'Mild Dementia',
        'riskColor': Colors.orange,
        'icon': Icons.warning_rounded,
        'description': 'Mild cognitive decline detected. Early intervention recommended.',
      },
      'moderate_demented': {
        'riskLevel': 'Moderate Dementia',
        'riskColor': Colors.red,
        'icon': Icons.error_outline,
        'description': 'Moderate cognitive decline. Consult a neurologist immediately.',
      },
    };
    return classMap[classCode] ?? classMap['non_demented']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Get prediction data from arguments
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    
    // Extract prediction from nested structure (API returns {"prediction": {...}, "success": true, ...})
    Map<String, dynamic> prediction = {};
    if (args is Map<String, dynamic>) {
      // If response has 'prediction' key (from API), extract it
      if (args.containsKey('prediction') && args['prediction'] is Map<String, dynamic>) {
        prediction = args['prediction'] as Map<String, dynamic>;
      } else {
        // Otherwise use args directly (for backward compatibility)
        prediction = args;
      }
    }
    
    // Provide defaults if prediction is empty
    if (prediction.isEmpty) {
      prediction = {'predicted_class': 'NonDemented', 'class_code': 'non_demented', 'confidence': 0.0, 'all_predictions': {}};
    }
    
    final String classCode = prediction['class_code'] ?? 'normal';
    final Map<String, dynamic> classInfo = getClassInfo(classCode);
    final double confidence = ((prediction['confidence'] ?? 0.0) as num).toDouble() * 100;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Alzheimer's Report"),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Card
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (classInfo['riskColor'] as Color).withOpacity(0.2),
                      (classInfo['riskColor'] as Color).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (classInfo['riskColor'] as Color).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      classInfo['icon'] as IconData,
                      size: 64,
                      color: classInfo['riskColor'] as Color,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      prediction['predicted_class'] ?? 'Unknown',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (classInfo['riskColor'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        classInfo['riskLevel'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: classInfo['riskColor'] as Color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Confidence: ${confidence.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Key Findings
            Text(
              "Key Findings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _FindingItem(
              icon: Icons.check_circle_outline,
              text: "Brain atrophy detected in specific regions",
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _FindingItem(
              icon: Icons.info_outline,
              text: "Memory function assessment shows mild decline",
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _FindingItem(
              icon: Icons.check_circle_outline,
              text: "Early intervention recommended",
              color: Colors.blue,
            ),

            const SizedBox(height: 30),

            // Recommendations
            Text(
              "Recommendations",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _RecommendationCard(
              icon: Icons.fitness_center,
              title: "Brain Exercises",
              description: "Engage in puzzles, memory games, and cognitive training",
            ),
            const SizedBox(height: 12),
            _RecommendationCard(
              icon: Icons.restaurant_menu,
              title: "Balanced Diet",
              description: "Maintain a Mediterranean-style diet rich in omega-3",
            ),
            const SizedBox(height: 12),
            _RecommendationCard(
              icon: Icons.local_hospital,
              title: "Regular Checkups",
              description: "Schedule follow-up with a neurologist in 3 months",
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: "Download Report",
              onPressed: () {
                // TODO: Generate and download PDF report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report downloaded successfully!')),
                );
              },
              icon: Icons.download,
            ),

            const SizedBox(height: 16),

            PrimaryButton(
              text: "Book Consultation",
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.findDoctor);
              },
              icon: Icons.calendar_today,
              color: theme.colorScheme.secondary,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FindingItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FindingItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
}
