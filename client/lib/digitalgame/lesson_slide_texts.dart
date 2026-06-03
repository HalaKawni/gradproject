class LessonSlideTexts {
  // Custom texts injected by the course viewer for AI-generated activities
  static final Map<int, List<String>> _custom = {};
  static void setCustom(int n, List<String> texts) => _custom[n] = texts;
  static void clearCustom(int n) => _custom.remove(n);

  static List<String> forLesson(int lessonNumber) {
    if (_custom.containsKey(lessonNumber)) return _custom[lessonNumber]!;
    switch (lessonNumber) {
      case 1:
        return [
          'A computer is an information processing machine. It takes input from the user, processes it, and outputs results.',
          'Computers combine hardware and software. Hardware refers to all physical parts. Software refers to all programs you use.',
          'The internet is a massive network of computers connected by cables and hardware. The World Wide Web and websites are the software that runs on those computers.',
          'Email lets you send messages to recipients. TO are main recipients. CC is Carbon Copy. BCC is Blind Carbon Copy.',
          'Files are documents stored on your computer or cloud. Organize files using folders arranged in a hierarchy.',
          'Useful student applications include Word Processing, Spreadsheets, and Presentations.',
          'Search engines find information matching keywords you enter. Use descriptive words when searching.',
          'Websites are made of webpages written in HTML. Each website has a unique URL. You view webpages using a browser like Chrome or Edge.',
          'Your inbox stores incoming emails. Sent folder stores emails you sent. Drafts folder stores unfinished emails.',
        ];

      case 2:
        return [
          'Digital citizenship means being safe, responsible, and friendly when using the internet and digital devices.',
          'Digital balance means having a healthy combination of digital and non-digital activities in your life.',
          'Being safe online means never sharing personal information like your name, address, or phone number with strangers.',
          'Cyberbullying is mean or harmful behavior toward others when online. Always be kind and respectful on the internet.',
          'Phishing is a type of email scam where criminals pretend to be trusted people to steal your personal information.',
          'Fake news refers to stories and images that are not real. Always check if information is from a trusted source before sharing.',
          'Misinformation is false or inaccurate information spread online. Think critically before believing or sharing content.',
          'A strong password uses a combination of letters, numbers, and special characters to protect your accounts.',
          'Never share your password with anyone except a trusted adult. Use different passwords for different websites.',
          'Online threats include phishing, cyberbullying, and fake news. Knowing about them helps you stay safe.',
        ];

      case 3:
        return [
          'Digital collaboration means working together with others using digital tools and technology.',
          'Collaboration is when a group of people share ideas and input on a project to achieve a common goal.',
          'Video conferencing technology allows people to meet face-to-face online from different locations.',
          'Applications like Google Docs and Microsoft Teams have collaboration features that let multiple people work on the same document.',
          'Global trends influence technology. Events and needs around the world drive new digital inventions and tools.',
          'Virtual reality is a trend where users experience a computer-generated environment as if it were real.',
          'Digital collaboration etiquette means being respectful, staying on topic, and contributing positively in online group work.',
          'Good digital collaboration requires clear communication, listening to others, and sharing responsibilities.',
        ];

      default:
        return [];
    }
  }
}
