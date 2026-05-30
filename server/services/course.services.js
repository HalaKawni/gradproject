const CourseModel = require('../model/course.model');

class CourseService {
  static async createCourse(userId, title, description, lessons, courseImageBase64) {
    const course = new CourseModel({ userId, title, description, lessons, courseImageBase64 });
    return await course.save();
  }

  static async getUserCourses(userId) {
    return await CourseModel.find({ userId }).sort({ updatedAt: -1 });
  }

  static async updateCourse(courseId, userId, updates) {
    return await CourseModel.findOneAndUpdate(
      { _id: courseId, userId },
      updates,
      { new: true }
    );
  }

  static async deleteCourse(courseId, userId) {
    return await CourseModel.findOneAndDelete({ _id: courseId, userId });
  }
}

module.exports = CourseService;
