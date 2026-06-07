const SlideCourseModel = require('../model/slideCourse.model');

class CourseService {
  static async createCourse(userId, title, description, lessons, courseImageBase64) {
    const course = new SlideCourseModel({
      userId,
      title,
      description,
      lessons,
      courseImageBase64,
    });
    return await course.save();
  }

  static async getUserCourses(userId) {
    return await SlideCourseModel.find({ userId }).sort({ updatedAt: -1 });
  }

  static async updateCourse(courseId, userId, updates) {
    return await SlideCourseModel.findOneAndUpdate(
      { _id: courseId, userId },
      updates,
      { new: true }
    );
  }

  static async deleteCourse(courseId, userId) {
    return await SlideCourseModel.findOneAndDelete({ _id: courseId, userId });
  }
}

module.exports = CourseService;
