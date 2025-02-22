import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';

class DownloadWorkoutPage extends StatefulWidget {
  const DownloadWorkoutPage({Key? key}) : super(key: key);

  @override
  _DownloadWorkoutPageState createState() => _DownloadWorkoutPageState();
}

class _DownloadWorkoutPageState extends State<DownloadWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final String baseUrl = 'https://exercise-app-8299a.web.app/exercises';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadWorkoutPlan([String? predefinedUrl]) async {
    if (!_formKey.currentState!.validate()) return;

    final url = predefinedUrl ?? _urlController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (predefinedUrl != null) {
        _urlController.text = url;
      }
    });

    try {
      final success = await context.read<WorkoutData>().downloadWorkoutPlan(url);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan downloaded successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to download workout plan. Make sure the URL points to a valid JSON file.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please check the URL and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Workout Plan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Example Plans Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example Plans',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          title: Text('Cardio Workout'),
                          trailing: Icon(Icons.download),
                          onTap: _isLoading ? null : () => _downloadWorkoutPlan('$baseUrl/cardio.json'),
                        ),
                        ListTile(
                          title: Text('Strength Training'),
                          trailing: Icon(Icons.download),
                          onTap: _isLoading ? null : () => _downloadWorkoutPlan('$baseUrl/strength.json'),
                        ),
                        ListTile(
                          title: Text('Lazy Day Workout'),
                          trailing: Icon(Icons.download),
                          onTap: _isLoading ? null : () => _downloadWorkoutPlan('$baseUrl/lazy.json'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Custom URL Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Workout Plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enter a URL to download a custom workout plan. The plan must be a JSON file following the required format.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Workout Plan URL',
                            hintText: 'Enter URL of the workout plan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a URL';
                            }
                            try {
                              final uri = Uri.parse(value);
                              if (!uri.isScheme('http') && !uri.isScheme('https')) {
                                return 'Please enter a valid HTTP or HTTPS URL';
                              }
                            } catch (e) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _downloadWorkoutPlan(),
                          icon: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(Icons.download),
                          label: Text('Download Custom Plan'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Required JSON Format:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '''
{
  "name": "Workout Name",
  "exercises": [
    {
      "name": "Exercise Name",
      "target": 100,
      "unit": "meters"
    }
  ]
}''',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}