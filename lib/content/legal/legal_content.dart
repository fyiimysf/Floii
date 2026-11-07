import '../../models/legal_document.dart';

/// Long-form legal copy, looked up per language with an English fallback.
///
/// Like the Learn catalogue, the prose lives here rather than in
/// `AppLocalizations` because it is reference text rather than interface
/// strings, and the volume grows quickly with each language. English is the
/// only catalogue today, so other locales render English body text behind
/// their own localized title.
class LegalContent {
  /// Privacy policy for [languageCode], or the English version when that
  /// language has no translation yet.
  static LegalDocument privacyPolicy(String languageCode) =>
      _privacy[languageCode] ?? _privacy['en']!;

  /// Terms & conditions for [languageCode], or the English version when that
  /// language has no translation yet.
  static LegalDocument termsAndConditions(String languageCode) =>
      _terms[languageCode] ?? _terms['en']!;

  static const Map<String, LegalDocument> _privacy = {
    'en': privacyPolicyEn,
  };

  static const Map<String, LegalDocument> _terms = {
    'en': termsConditionsEn,
  };
}

const LegalDocument privacyPolicyEn = LegalDocument(
  intro:
      'Floii is built to be private by default. This policy explains what the '
      'app does with your information — in short, everything you track stays on '
      'your device.',
  sections: [
    LegalSection('Information You Provide', [
      'You may record period dates, cycle length, moods, symptoms, notes and '
          'preferences such as language and theme. This information is stored '
          'only on your device.',
      'You are **not required** to create an account, and you never have to '
          'share your real name or email address to use the app.',
    ]),
    LegalSection('How Your Data Is Used', [
      'Your entries are used solely to calculate cycle predictions, phase '
          'information, statistics and reminders inside the app. All of this '
          'happens on your device.',
      '!!Your entries are never sent to us, and they are never used to build an '
          'advertising profile.!!',
    ]),
    LegalSection('Storage & Security', [
      'Data is kept in a local database on your device. Because it never leaves '
          'your phone, its security also depends on your device passcode and the '
          'protections built into your operating system.',
      'You can export a backup at any time, and you can erase everything from '
          '**Settings → Data → Factory Reset**. Deleting the app removes its '
          'local data as well.',
    ]),
    LegalSection('Sharing & Third Parties', [
      'We do not sell, rent or share your personal data. The app contains no '
          'third-party advertising networks and no analytics trackers.',
      'If you choose to send feedback, only the details you type are shared, and '
          'only through the channel you pick. Sending feedback is always '
          'optional.',
    ]),
    LegalSection('Notifications', [
      'If you enable reminders, they are scheduled locally on your device. No '
          'reminder content is sent through a server, and you can turn them off '
          'at any time in Settings.',
    ]),
    LegalSection("Children's Privacy", [
      'Floii is not directed at children under 13, and we do not knowingly '
          'collect information from them.',
    ]),
    LegalSection('Your Choices', [
      'You stay in control of your information. You can edit or delete any '
          'entry, export a backup, or erase all data from the Data section of '
          'Settings.',
    ]),
    LegalSection('Changes to This Policy', [
      'We may update this policy as the app evolves. When we do, we will revise '
          'the date shown at the top of this page.',
    ]),
    LegalSection('Contact Us', [
      'If you have questions about this policy, reach us through **Send '
          'Feedback** in Settings.',
    ]),
  ],
);

const LegalDocument termsConditionsEn = LegalDocument(
  intro:
      'Please read these terms before using Floii. By using the app, you agree '
      'to them.',
  sections: [
    LegalSection('Acceptance of Terms', [
      'By downloading, accessing or using Floii, you agree to be bound by these '
          'terms. If you do not agree with any part of them, please do not use '
          'the app.',
    ]),
    LegalSection('Use of the App', [
      'Floii is provided for your personal, non-commercial use. You agree to use '
          'it only for lawful purposes and not to copy, modify, reverse '
          'engineer, or redistribute the app except as permitted by law.',
    ]),
    LegalSection('Not Medical Advice', [
      'Floii provides estimates based on the dates and details you enter. It is '
          '**not a medical device** and it does not diagnose, treat, prevent or '
          'cure any condition.',
      '!!Do not rely on Floii as a method of contraception.!! Predictions are '
          'estimates and can be inaccurate. Always consult a qualified '
          'healthcare professional for medical decisions.',
    ]),
    LegalSection('Accuracy of Predictions', [
      'Predictions improve as you record more cycles, but no prediction is '
          'guaranteed. Your cycle can change for many reasons, including stress, '
          'illness, travel and medication.',
    ]),
    LegalSection('Your Content & Responsibilities', [
      'You are responsible for the accuracy of the information you enter and for '
          'keeping your own backups. If you lose your device or uninstall the '
          'app, data that you have not exported may not be recoverable.',
    ]),
    LegalSection('Intellectual Property', [
      'The app, including its name, logo, design and content, is owned by us or '
          'our licensors and is protected by intellectual property laws.',
    ]),
    LegalSection('Disclaimer of Warranties', [
      'Floii is provided "as is" and "as available", without warranties of any '
          'kind, whether express or implied, including fitness for a particular '
          'purpose.',
    ]),
    LegalSection('Limitation of Liability', [
      'To the fullest extent permitted by law, we are not liable for any '
          'indirect, incidental or consequential damages arising from your use '
          'of, or inability to use, the app.',
    ]),
    LegalSection('Changes to These Terms', [
      'We may update these terms as the app evolves. Continued use of Floii '
          'after a change means you accept the updated terms.',
    ]),
    LegalSection('Contact Us', [
      'If you have questions about these terms, reach us through **Send '
          'Feedback** in Settings.',
    ]),
  ],
);
