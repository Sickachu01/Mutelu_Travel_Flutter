const express = require('express');
const router = express.Router();
const Actor = require('../models/Actor');

// GET all data
router.get('/', async (req, res) => {
    try {
        const actors = await Actor.find();
        res.status(200).json(actors);
    } catch (err) {
        res.status(500).send('Internal Server Error');
    }
});

// GET 
router.get('/:id', async (req, res) => {
    try {
        const actor = await Actor.findById(req.params.id);
        if (!actor) return res.status(404).send('Not found');
        res.status(200).json(actor);
    } catch (err) {
        res.status(500).send('Internal Server Error');
    }
});

// POST
router.post('/', async (req, res) => {
    try {
        if (Array.isArray(req.body)) {
            const actors = await Actor.insertMany(req.body);
            res.status(201).json(actors);
        } else {
            const actor = new Actor(req.body);
            await actor.save();
            res.status(201).json(actor);
        }
    } catch (err) {
        console.error('Error:', err);
        if (err.code === 11000) {
            res.status(400).send('The information is already');
        } else {
            res.status(500).send('Internal Server Error');
        }
    }
});

// PUT (update)
router.put('/:id', async (req, res) => {
    try {
        const updated = await Actor.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (!updated) return res.status(404).send('Not found');
        res.status(200).json(updated);
    } catch (err) {
        res.status(500).send('Internal Server Error');
    }
});

// PATCH
router.patch('/:id', async (req, res) => {
    try {
        const updated = await Actor.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (!updated) return res.status(404).send('Not found');
        res.status(200).json(updated);
    } catch (err) {
        res.status(500).send('Internal Server Error');
    }
});

// DELETE
router.delete('/:id', async (req, res) => {
    try {
        const deleted = await Actor.findByIdAndDelete(req.params.id);
        if (!deleted) return res.status(404).send('Not found');
        res.status(200).send('Deleted');
    } catch (err) {
        res.status(500).send('Internal Server Error');
    }
});

module.exports = router;