const mongoose = require('mongoose');

const contactSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Nama tidak boleh kosong'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Email tidak boleh kosong'],
    trim: true,
    lowercase: true,
    match: [
      /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
      'Format email tidak valid',
    ],
  },
  message: {
    type: String,
    required: [true, 'Pesan tidak boleh kosong'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Contact', contactSchema);
