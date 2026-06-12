const coursesService = require('../services/courses.service');

async function getMineCourses(req, res) {
  try {
    const courses = await coursesService.getMineCourses(req.user._id, req.query.lang);
    return res.json({ success: true, data: courses });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch your courses.',
      error: error.message,
    });
  }
}

async function createMineCourse(req, res) {
  try {
    const course = await coursesService.createMineCourse(
      req.body,
      req.user._id,
      req.query.lang
    );
    return res.status(201).json({ success: true, data: course });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to create course.',
    });
  }
}

async function updateMineCourse(req, res) {
  try {
    const course = await coursesService.updateMineCourse(
      req.params.id,
      req.body,
      req.user._id,
      req.query.lang
    );
    return res.json({ success: true, data: course });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to update course.',
    });
  }
}

async function deleteMineCourse(req, res) {
  try {
    await coursesService.deleteMineCourse(req.params.id, req.user._id);
    return res.json({ success: true, message: 'Course deleted successfully' });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to delete course.',
    });
  }
}

async function requestMineCourseVerification(req, res) {
  try {
    const course = await coursesService.requestMineCourseVerification(
      req.params.id,
      req.user._id,
      req.query.lang
    );
    return res.json({ success: true, data: course });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to request verification.',
    });
  }
}

async function getPublicCourses(req, res) {
  try {
    const courses = await coursesService.getPublicCourses(req.user, req.query.lang);
    return res.json({ success: true, data: courses });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch courses.',
      error: error.message,
    });
  }
}

async function getCommunityCourses(req, res) {
  try {
    const courses = await coursesService.getCommunityCourses(req.user._id, req.query.lang);
    return res.json({ success: true, data: courses });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch community courses.',
      error: error.message,
    });
  }
}

async function getPublicCourseLevels(req, res) {
  try {
    const levels = await coursesService.getPublicCourseLevels(
      req.params.courseId,
      req.query.lang
    );
    return res.json({ success: true, data: levels });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
}

async function getCourseProgress(req, res) {
  try {
    const progress = await coursesService.getCourseProgress(
      req.params.courseId,
      req.user._id
    );
    return res.json({ success: true, data: progress });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
}

async function completeCourseLevel(req, res) {
  try {
    const progress = await coursesService.completeCourseLevel(
      req.params.courseId,
      req.user,
      req.params.levelId,
      req.body || {}
    );
    return res.json({ success: true, data: progress });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
}

async function trackCourseEvent(req, res) {
  try {
    const interaction = await coursesService.trackCourseEvent(
      req.params.courseId,
      req.user,
      req.body?.eventType
    );
    return res.status(201).json({ success: true, data: interaction });
  } catch (error) {
    const statusCode = error.message === 'Invalid event type' ? 400 : 404;
    return res.status(statusCode).json({
      success: false,
      message: error.message,
    });
  }
}

async function addCourseComment(req, res) {
  try {
    const course = await coursesService.addCourseComment(
      req.params.courseId,
      req.body.message,
      req.user,
      req.query.lang
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found.',
      });
    }

    return res.json({
      success: true,
      message: 'Comment added successfully.',
      data: course,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to add comment.',
    });
  }
}

async function deleteCourseComment(req, res) {
  try {
    const course = await coursesService.deleteCourseComment(
      req.params.courseId,
      req.params.commentId,
      req.user,
      req.query.lang
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found.',
      });
    }

    return res.json({
      success: true,
      message: 'Comment deleted successfully.',
      data: course,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to delete comment.',
    });
  }
}

async function rateCourse(req, res) {
  try {
    const course = await coursesService.rateCourse(
      req.params.courseId,
      req.body.rating,
      req.user,
      req.query.lang
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found.',
      });
    }

    return res.json({
      success: true,
      message: 'Rating saved successfully.',
      data: course,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to save rating.',
    });
  }
}

module.exports = {
  getMineCourses,
  createMineCourse,
  updateMineCourse,
  deleteMineCourse,
  requestMineCourseVerification,
  getPublicCourses,
  getCommunityCourses,
  getPublicCourseLevels,
  getCourseProgress,
  completeCourseLevel,
  trackCourseEvent,
  addCourseComment,
  deleteCourseComment,
  rateCourse,
};
