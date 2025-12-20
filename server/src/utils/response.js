const successResponse = (res, data, message = 'Success', code = 200) => {
  return res.status(code).json({
    status: 'success',
    message,
    data,
  });
};

const errorResponse = (res, message = 'Something went wrong', code = 500, error = null) => {
  if (process.env.NODE_ENV === 'development' && error) {
    console.error(error);
  }
  return res.status(code).json({
    status: 'error',
    message,
    error: process.env.NODE_ENV === 'development' ? error : undefined,
  });
};

module.exports = { successResponse, errorResponse };
