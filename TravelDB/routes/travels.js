const express = require('express');
const router = express.Router();
const Travel = require('../models/Travel');

// GET all data
router.get('/', async (req, res) => {
    try {
        const travels = await Travel.find();
        res.status(200).json(travels);
    } catch (err) {
        console.error('Error fetching travels:', err);
        res.status(500).send('Internal Server Error');
    }
});

// GET a specific travel by ID
router.get('/:id', async (req, res) => {
    try {
        const travel = await Travel.findById(req.params.id);
        if (!travel) return res.status(404).send('Not found');
        res.status(200).json(travel);
    } catch (err) {
        console.error('Error fetching travel:', err);
        res.status(500).send('Internal Server Error');
    }
});

// POST new travel
router.post('/', async (req, res) => {
    try {
        if (Array.isArray(req.body)) {
            const travels = await Travel.insertMany(req.body);
            res.status(201).json(travels);
        } else {
            const travel = new Travel(req.body);
            await travel.save();
            res.status(201).json(travel);
        }
    } catch (err) {
        console.error('Error creating travel:', err);
        if (err.code === 11000) {
            res.status(400).send('The information already exists');
        } else {
            res.status(500).send('Internal Server Error');
        }
    }
});

// PUT (update) existing travel
router.put('/:id', async (req, res) => {
    try {
        const updated = await Travel.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (!updated) return res.status(404).send('Not found');
        res.status(200).json(updated);
    } catch (err) {
        console.error('Error updating travel:', err);
        res.status(500).send('Internal Server Error');
    }
});

// PATCH (partially update) existing travel
router.patch('/:id', async (req, res) => {
    try {
        const updated = await Travel.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (!updated) return res.status(404).send('Not found');
        res.status(200).json(updated);
    } catch (err) {
        console.error('Error partially updating travel:', err);
        res.status(500).send('Internal Server Error');
    }
});

// DELETE a specific travel by ID
router.delete('/:id', async (req, res) => {
    try {
        const deleted = await Travel.findByIdAndDelete(req.params.id);
        if (!deleted) return res.status(404).send('Not found');
        res.status(200).send('Deleted');
    } catch (err) {
        console.error('Error deleting travel:', err);
        res.status(500).send('Internal Server Error');
    }
});

module.exports = router;
