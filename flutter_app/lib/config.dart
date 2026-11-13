import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apiBase => dotenv.env['API_URL'] ?? 'http://localhost:4000';

String imageUrl(String path) => path.startsWith('http') ? path : '$apiBase$path';
