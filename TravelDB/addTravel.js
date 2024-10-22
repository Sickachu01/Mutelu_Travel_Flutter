document.getElementById('travel-form').addEventListener('submit', async function(event) {
    event.preventDefault(); // ป้องกันการรีเฟรชหน้าเมื่อส่งฟอร์ม

    // รวบรวมข้อมูลจากฟอร์ม
    const travelData = {
        namelocation: document.getElementById('namelocation').value,
        subname: document.getElementById('subname').value,
        detail: document.getElementById('detail').value,
        side: document.getElementById('side').value,
        location: document.getElementById('location').value,
        time: document.getElementById('time').value,
        Image1: document.getElementById('Image1').value,
        Image2: document.getElementById('Image2').value
    };

    try {
        const response = await fetch('http://localhost:3000/travels', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(travelData), // แปลงข้อมูลเป็น JSON
        });

        if (response.ok) {
            alert('เพิ่มการเดินทางใหม่สำเร็จ!');
            window.location.href = 'index.html'; // กลับไปที่หน้าหลักหลังจากบันทึกสำเร็จ
        } else {
            const errorData = await response.json();
            alert('เกิดข้อผิดพลาด: ' + errorData.message);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    }
});
