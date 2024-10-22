const express = require('express');
const cors = require('cors'); // Make sure to install this package
const mongoose = require('mongoose');
const travelsRoutes = require('./routes/travels');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors()); // Allow CORS
app.use(express.json()); // Parse JSON bodies

// Connect to MongoDB (make sure your MongoDB server is running)
mongoose.connect('mongodb://localhost:27017/your-db-name', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => {
    console.log('MongoDB connected');
}).catch(err => {
    console.error('MongoDB connection error:', err);
});

// Routes
app.use('/travels', travelsRoutes);

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
