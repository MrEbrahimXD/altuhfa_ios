String removeTashkeel(String input) {
  return input.replaceAll(
    RegExp(r'[\u0617-\u061A\u064B-\u0652\u0670\u06D6-\u06ED]'),
    '',
  );
}

String normalizeArabic(String input) {
  return input
      .replaceAll(RegExp(r'[إأآا]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}

String normalizeForSearch(String input) {
  return normalizeArabic(removeTashkeel(input)).trim();
}

String toArabicNumeral(int number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((d) => arabicDigits[int.parse(d)])
      .join();
}

String formatNumeral(int number, {bool arabic = true}) {
  return arabic ? toArabicNumeral(number) : number.toString();
}

/// Compare two Arabic words with fuzzy matching:
/// strips tashkeel, normalizes alef/taa/yaa, allows edit distance.
bool arabicWordsMatch(String spoken, String expected) {
  final a = normalizeForSearch(spoken);
  final b = normalizeForSearch(expected);
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  // Prefix match (STT may cut off or add ending)
  if (a.length >= 2 && b.length >= 2) {
    if (a.startsWith(b) || b.startsWith(a)) return true;
  }
  // Generous edit distance: allow up to ~30% of the longer word, minimum 2
  final maxLen = a.length > b.length ? a.length : b.length;
  final threshold = maxLen <= 3 ? 1 : (maxLen * 0.35).ceil().clamp(2, 4);
  if (_editDistance(a, b) <= threshold) return true;
  return false;
}

/// Try to match spokenWords against expectedWords starting from expectedStart.
/// Returns how many expected words were matched (can be 0).
/// Handles STT merging two words into one, splitting one word into two,
/// and inserting extra filler words.
int matchSpokenToExpected(
  List<String> spokenWords,
  List<String> expectedWords,
  int expectedStart,
) {
  if (spokenWords.isEmpty || expectedStart >= expectedWords.length) return 0;

  int ei = expectedStart;
  int si = 0;

  while (si < spokenWords.length && ei < expectedWords.length) {
    final spoken = normalizeForSearch(spokenWords[si]);
    final expected = normalizeForSearch(expectedWords[ei]);

    // Direct match
    if (arabicWordsMatch(spokenWords[si], expectedWords[ei])) {
      ei++;
      si++;
      continue;
    }

    // STT merged two expected words into one spoken word
    // e.g. spoken="رحمة الغفور" as "رحمةالغفور"
    if (ei + 1 < expectedWords.length) {
      final merged =
          normalizeForSearch('${expectedWords[ei]}${expectedWords[ei + 1]}');
      if (arabicWordsMatch(spokenWords[si],
              '${expectedWords[ei]}${expectedWords[ei + 1]}') ||
          _editDistance(spoken, merged) <= 2) {
        ei += 2;
        si++;
        continue;
      }
    }

    // STT split one expected word into two spoken words
    // e.g. expected="الغفور" spoken as "ال غفور"
    if (si + 1 < spokenWords.length) {
      final joined =
          normalizeForSearch('${spokenWords[si]}${spokenWords[si + 1]}');
      if (arabicWordsMatch(
              '${spokenWords[si]}${spokenWords[si + 1]}', expectedWords[ei]) ||
          _editDistance(joined, expected) <= 2) {
        ei++;
        si += 2;
        continue;
      }
    }

    // Skip this spoken word as filler/noise
    si++;
  }

  return ei - expectedStart;
}

int _editDistance(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  // Early exit if difference is too large
  if ((m - n).abs() > 5) return (m - n).abs();
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (int i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      int val = dp[i - 1][j] + 1;
      if (dp[i][j - 1] + 1 < val) val = dp[i][j - 1] + 1;
      if (dp[i - 1][j - 1] + cost < val) val = dp[i - 1][j - 1] + cost;
      dp[i][j] = val;
    }
  }
  return dp[m][n];
}
