const CourseService = require('../services/course.services');

exports.createCourse = async (req, res) => {
  try {
    const { title, description, lessons, courseImageBase64 } = req.body;
    if (!title) return res.status(400).json({ status: false, error: 'Title is required' });
    const course = await CourseService.createCourse(
      req.user._id, title, description || '', lessons || [], courseImageBase64 || null
    );
    res.status(201).json({ status: true, course });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'Failed to save course' });
  }
};

exports.getUserCourses = async (req, res) => {
  try {
    const courses = await CourseService.getUserCourses(req.user._id);
    res.json({ status: true, courses });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.updateCourse = async (req, res) => {
  try {
    const { courseImageBase64, isPublished, title, description, lessons } = req.body;
    const updates = {};
    if (courseImageBase64 !== undefined) updates.courseImageBase64 = courseImageBase64;
    if (isPublished !== undefined) updates.isPublished = isPublished;
    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (lessons !== undefined) updates.lessons = lessons;
    const updated = await CourseService.updateCourse(req.params.id, req.user._id, updates);
    if (!updated) return res.status(404).json({ status: false, error: 'Course not found' });
    res.json({ status: true, course: updated });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.deleteCourse = async (req, res) => {
  try {
    const deleted = await CourseService.deleteCourse(req.params.id, req.user._id);
    if (!deleted) return res.status(404).json({ status: false, error: 'Course not found' });
    res.json({ status: true });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};
