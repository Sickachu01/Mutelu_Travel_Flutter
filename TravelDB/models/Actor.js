const mongoose = require('mongoose');

const actorSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    nationality: String,       
    birthDate: String,
    birthPlace: String,
    movies: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Movie' }],
    tvShows: [{ type: mongoose.Schema.Types.ObjectId, ref: 'TVShow' }],
    profileImage: String
});

module.exports = mongoose.model('Actor', actorSchema);