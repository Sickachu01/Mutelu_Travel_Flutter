const mongoose = require('mongoose');

const travelSchema = new mongoose.Schema({
    namelocation: { type: String, required: true, unique: true },
    subname: String,       
    detail: String,
    side: String,
    location: String,
    time: String,  
    Image1: String,
    Image2: String,
});

module.exports = mongoose.model('Travel', travelSchema);