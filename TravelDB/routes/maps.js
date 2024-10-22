const express = require("express");
const cors = require("cors"); // เพิ่ม CORS
const router = express.Router();
const Map = require("../models/Map"); // แก้ไขให้ถูกต้อง

const app = express();
app.use(cors()); // ใช้ CORS เพื่ออนุญาตให้เข้าถึง API จากที่อื่น
app.use(express.json()); // ใช้เพื่อให้สามารถรับ JSON ใน body ได้

// GET all data
router.get("/", async (req, res) => {
  try {
    const maps = await Map.find(); // เปลี่ยนจาก Travel เป็น Map
    res.status(200).json(maps);
  } catch (err) {
    console.error("Error fetching maps:", err);
    res.status(500).send("Internal Server Error");
  }
});

// GET a specific map by ID
router.get("/:id", async (req, res) => {
  try {
    const map = await Map.findById(req.params.id); // เปลี่ยนจาก Travel เป็น Map
    if (!map) return res.status(404).send("Not found");
    res.status(200).json(map);
  } catch (err) {
    console.error("Error fetching map:", err);
    res.status(500).send("Internal Server Error");
  }
});

// POST new map
router.post("/", async (req, res) => {
  try {
    if (Array.isArray(req.body)) {
      const maps = await Map.insertMany(req.body); // เปลี่ยนจาก Travel เป็น Map
      res.status(201).json(maps);
    } else {
      const map = new Map(req.body); // เปลี่ยนจาก Travel เป็น Map
      await map.save();
      res.status(201).json(map);
    }
  } catch (err) {
    console.error("Error creating map:", err);
    if (err.code === 11000) {
      res.status(400).send("The information already exists");
    } else {
      res.status(500).send("Internal Server Error");
    }
  }
});

// PUT (update) existing map
router.put("/:id", async (req, res) => {
  try {
    const updated = await Map.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!updated) return res.status(404).send("Not found");
    res.status(200).json(updated);
  } catch (err) {
    console.error("Error updating map:", err);
    res.status(500).send("Internal Server Error");
  }
});

// PATCH (partially update) existing map
router.patch("/:id", async (req, res) => {
  try {
    const updated = await Map.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!updated) return res.status(404).send("Not found");
    res.status(200).json(updated);
  } catch (err) {
    console.error("Error partially updating map:", err);
    res.status(500).send("Internal Server Error");
  }
});

// DELETE a specific map by ID
router.delete("/:id", async (req, res) => {
  try {
    const deleted = await Map.findByIdAndDelete(req.params.id); // เปลี่ยนจาก Travel เป็น Map
    if (!deleted) return res.status(404).send("Not found");
    res.status(200).send("Deleted");
  } catch (err) {
    console.error("Error deleting map:", err);
    res.status(500).send("Internal Server Error");
  }
});

// GET locations by query
router.get("/search", async (req, res) => {
  const query = req.query.q; // ดึงคำค้นหาจาก query parameter
  if (!query) {
    return res.status(400).json({ error: 'Query parameter "q" is required' });
  }

  try {
    const locations = await Map.find({
      namelocation: { $regex: query, $options: "i" }, // ค้นหาตาม namelocation
    });

    res.status(200).json(locations);
  } catch (err) {
    console.error("Error searching locations:", err);
    res.status(500).send("Internal Server Error");
  }
});

// GET all unique sides
router.get("/sides", async (req, res) => {
  try {
    const sides = await Map.distinct("side"); // ดึงค่า unique จาก field side
    res.status(200).json(sides);
  } catch (err) {
    console.error("Error fetching sides:", err);
    res.status(500).send("Internal Server Error");
  }
});

// GET locations by side
router.get("/places", async (req, res) => {
  const { side, count } = req.query; // ดึงข้อมูลจาก query parameters

  if (!side) {
    return res.status(400).json({ error: 'Query parameter "side" is required' });
  }

  try {
    // ค้นหาสถานที่ตามด้านและจำนวนที่ต้องการ
    const locations = await Map.find({ side }).limit(parseInt(count)); // เพิ่มการจำกัดจำนวน
    res.status(200).json(locations);
  } catch (err) {
    console.error("Error fetching locations:", err);
    res.status(500).send("Internal Server Error");
  }
});

// Export the router
module.exports = router;

// Start the server (เพิ่มโค้ดนี้ถ้าคุณต้องการรัน server ที่นี่)
const PORT = process.env.PORT || 3000;
app.use("/api/maps", router); // ตั้งค่า router ให้ทำงานที่ /api/maps
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
