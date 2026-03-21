class ZodiacUtils {
  static const signs = <String>[
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  static const localizedNames = <String, String>{
    'Aries': '白羊座',
    'Taurus': '金牛座',
    'Gemini': '双子座',
    'Cancer': '巨蟹座',
    'Leo': '狮子座',
    'Virgo': '处女座',
    'Libra': '天秤座',
    'Scorpio': '天蝎座',
    'Sagittarius': '射手座',
    'Capricorn': '摩羯座',
    'Aquarius': '水瓶座',
    'Pisces': '双鱼座',
  };

  static String? zodiacFromBirthday(DateTime? birthday) {
    if (birthday == null) return null;
    final m = birthday.month;
    final d = birthday.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Aries';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Taurus';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 21)) return 'Gemini';
    if ((m == 6 && d >= 22) || (m == 7 && d <= 22)) return 'Cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Leo';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Virgo';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 23)) return 'Libra';
    if ((m == 10 && d >= 24) || (m == 11 && d <= 22)) return 'Scorpio';
    if ((m == 11 && d >= 23) || (m == 12 && d <= 21)) return 'Sagittarius';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'Capricorn';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Aquarius';
    return 'Pisces';
  }

  static String displayName(String sign) => localizedNames[sign] ?? sign;

  static DateTime? tryParseBirthday(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String formatBirthday(DateTime? birthday) {
    if (birthday == null) return '';
    final month = birthday.month.toString().padLeft(2, '0');
    final day = birthday.day.toString().padLeft(2, '0');
    return '${birthday.year}-$month-$day';
  }
}
