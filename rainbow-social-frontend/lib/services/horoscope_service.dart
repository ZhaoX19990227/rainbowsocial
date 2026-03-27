import '../models/horoscope_data.dart';
import 'api_client.dart';

class HoroscopeService {
  HoroscopeService(this._client);

  final ApiClient _client;

  Future<HoroscopeData> getToday(
    String token, {
    DateTime? date,
  }) async {
    final response = await _client.get(
      '/horoscope/today',
      token: token,
      query: {
        if (date != null) 'date': _formatDate(date),
      },
    );
    return HoroscopeData.fromJson(response['data'] as Map<String, dynamic>);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
