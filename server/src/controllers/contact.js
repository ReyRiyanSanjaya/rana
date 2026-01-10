const Contact = require('../models/contact');

exports.createMessage = async (req, res) => {
  try {
    const { name, email, message } = req.body;
    const newMessage = new Contact({ name, email, message });
    await newMessage.save();
    res.status(201).json({ success: true, message: 'Pesan berhasil terkirim!' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Gagal mengirim pesan', error: error.message });
  }
};
