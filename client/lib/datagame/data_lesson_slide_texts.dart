class DataLessonSlideTexts {
  static List<String> forLesson(int lessonNumber) {
    switch (lessonNumber) {
      case 1:
        return [
          'Today, we will explore the first step in Data Science: Collecting Data. The topic of collecting data involves understanding different forms of data and some methods for collecting it.',
          'Data represented by numbers is called numerical data. Data that is not represented by numbers is called non-numerical data.',
          'You gather numerical data when you count things. How many pets does each person have? How many chocolate chips are in each cookie? You also gather numerical data when you measure things like height or temperature.',
          'You gather non-numerical data when you describe or sort things. What kind of pets does each person have? What is your favorite type of cookie? Sorting food into categories like veggie, fruit, snack, and dessert is also non-numerical data.',
          'Pick which data to collect based on the questions you want to answer. Data helps us make decisions and plan for the future.',
          'Ways to collect data: Questionnaire — a list of questions for a group of people. Observation — writing down data from a science experiment. Research — searching the library or internet. Sensors — devices like a phone or pedometer that track data automatically.',
          'Data Scientists specialize in collecting, organizing, and applying data. They help predict weather, understand how people use the internet, and help doctors find better treatments.',
          'Data is everywhere — from apps on your phone to online recommendations. Data science is like being a detective of information: collecting clues, finding patterns, and learning new things about the world.',
        ];

      case 2:
        return [
          'Once we collect data, we need to arrange it so that it is easy to read and understand. Organized data helps us find patterns and make decisions.',
          'When we organize data into charts and graphs, we can quickly see patterns, make comparisons, and draw conclusions.',
          'A bar graph uses rectangular bars to compare different categories. The taller the bar, the larger the value.',
          'A pie chart is a circle divided into slices. Each slice represents a part of the whole. The bigger the slice, the bigger the share.',
          'A line graph shows how data changes over time. If the line goes up, the value is increasing. If it goes down, the value is decreasing.',
          'A frequency table organizes data into rows and columns. It shows how often each value appears in a data set.',
        ];

      default:
        return [];
    }
  }
}
