const coursesService = require('../../services/admin/courses.service');

exports.getCourses = async (req, res) => {
  try {
    const courses = await coursesService.getCourses();
    res.json(courses);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createCourse = async (req, res) => {
  try {
    const course = await coursesService.createCourse(
      req.body,
      req.user.id // comes from auth middleware
    );
    res.status(201).json(course);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.updateCourse = async (req, res) => {
  try {
    const course = await coursesService.updateCourse(
      req.params.id,
      req.body,
      req.user.id
    );
    res.json(course);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteCourse = async (req, res) => {
  try {
    await coursesService.deleteCourse(req.params.id);
    res.json({ message: 'Course deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
