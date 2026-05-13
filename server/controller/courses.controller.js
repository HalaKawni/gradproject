const coursesService = require('../services/courses.service');

async function getPublicCourses(req, res) {
  try {
    const courses = await coursesService.getPublicCourses();
    return res.json({ success: true, data: courses });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch courses.',
      error: error.message,
    });
  }
}

async function getPublicCourseLevels(req, res) {
  try {
    const levels = await coursesService.getPublicCourseLevels(
      req.params.courseId
    );
    return res.json({ success: true, data: levels });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
}

module.exports = {
  getPublicCourses,
  getPublicCourseLevels,
};
