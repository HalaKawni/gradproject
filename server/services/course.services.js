const SlideCourseModel = require('../model/slideCourse.model');
const {
  localizeDocument,
  localizeDocuments,
  prepareLocalizedInput,
} = require('./localizedContent.service');

const SLIDE_COURSE_LOCALIZATION_CONFIG = {
  directFields: ['title', 'description'],
  recursiveFields: ['title', 'description', 'instructions', 'instruction', 'lessonText', 'text', 'content', 'body', 'summary', 'subtitle'],
};

class CourseService {
  static async createCourse(userId, title, description, lessons, courseImageBase64, language) {
    const localizedPayload = prepareLocalizedInput(
      {
        title,
        description,
        lessons,
      },
      SLIDE_COURSE_LOCALIZATION_CONFIG
    );

    const course = new SlideCourseModel({
      userId,
      title: localizedPayload.title,
      description: localizedPayload.description,
      lessons: localizedPayload.lessons,
      courseImageBase64,
    });
    const savedCourse = await course.save();
    return localizeDocument(savedCourse, {
      ...SLIDE_COURSE_LOCALIZATION_CONFIG,
      language,
    });
  }

  static async getUserCourses(userId, language) {
    const courses = await SlideCourseModel.find({ userId }).sort({ updatedAt: -1 });
    return localizeDocuments(courses, {
      ...SLIDE_COURSE_LOCALIZATION_CONFIG,
      language,
    });
  }

  static async updateCourse(courseId, userId, updates, language) {
    const localizedUpdates = prepareLocalizedInput(
      updates,
      SLIDE_COURSE_LOCALIZATION_CONFIG
    );

    const updatedCourse = await SlideCourseModel.findOneAndUpdate(
      { _id: courseId, userId },
      localizedUpdates,
      { new: true }
    );

    if (!updatedCourse) {
      return null;
    }

    return localizeDocument(updatedCourse, {
      ...SLIDE_COURSE_LOCALIZATION_CONFIG,
      language,
    });
  }

  static async deleteCourse(courseId, userId) {
    return await SlideCourseModel.findOneAndDelete({ _id: courseId, userId });
  }
}

module.exports = CourseService;
