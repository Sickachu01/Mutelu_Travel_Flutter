const mongoose = require('mongoose');

const mapSchema = new mongoose.Schema({
    namelocation: { type: String, required: true, unique: true }, 
    side: String,
    location: String,
    time: String,
    Image1: String,
    latitude: { type: Number, required: true },  
    longitude: { type: Number, required: true }, 
});

module.exports = mongoose.model('Map', mapSchema);
