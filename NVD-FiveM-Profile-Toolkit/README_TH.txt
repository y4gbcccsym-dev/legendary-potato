NVD-FiveM-Profile-Toolkit (คู่มือภาษาไทย)
=========================================

วัตถุประสงค์
------------
ชุดสคริปต์นี้ช่วยจัดการโปรไฟล์ NVIDIA สำหรับ FiveM และ GTA V อย่างปลอดภัย โดยใช้ NVIDIA Profile Inspector และไฟล์ .nip

การเตรียมไฟล์ก่อนใช้งาน
-------------------------
1) วางไฟล์ nvidiaProfileInspector.exe ไว้ที่:
   - NVD-FiveM-Profile-Toolkit\tools\nvidiaProfileInspector.exe
   หรือ
   - NVD-FiveM-Profile-Toolkit\nvidiaProfileInspector.exe

2) วางไฟล์โปรไฟล์ที่ต้องการใช้ไว้ที่:
   - NVD-FiveM-Profile-Toolkit\profiles\FiveM_GTA5_Performance.nip

3) โฟลเดอร์สำรอง:
   - NVD-FiveM-Profile-Toolkit\backups
   (สคริปต์จะสร้างให้อัตโนมัติถ้ายังไม่มี)

วิธีรันสคริปต์
--------------
1) คลิกขวาไฟล์ Apply-NVD-FiveM.ps1
2) เลือก "Run with PowerShell"
3) ทำตามเมนูภาษาไทยบนหน้าจอ

เมนูหลักทำอะไรบ้าง
-------------------
[1] Check system / ตรวจสอบระบบ
- ตรวจว่ามีการ์ดจอ NVIDIA หรือไม่
- แสดงชื่อการ์ดจอและเวอร์ชันไดรเวอร์ (ถ้ามี)
- ตรวจไฟล์ nvidiaProfileInspector.exe
- ตรวจไฟล์โปรไฟล์ FiveM_GTA5_Performance.nip
- แสดงไฟล์สำรองล่าสุด (ถ้ามี)

[2] Backup NVIDIA customized profiles / สำรองโปรไฟล์ NVIDIA เดิม
- สั่ง export โปรไฟล์ที่ปรับแต่งไว้ด้วย nvidiaProfileInspector.exe -exportCustomized
- คัดลอกไฟล์ .nip ล่าสุดมาเก็บในโฟลเดอร์ backups
- ตั้งชื่อไฟล์สำรองเป็น NVIDIA_Custom_Backup_yyyyMMdd_HHmmss.nip

[3] Apply FiveM + GTA V NVIDIA profile / นำเข้าโปรไฟล์ FiveM + GTA V
- สำรองข้อมูลก่อนอัตโนมัติ
- นำเข้าไฟล์ profiles\FiveM_GTA5_Performance.nip ด้วย -silentImport
- เสร็จแล้วจะแจ้งให้ปิดเกม/Launcher ที่เกี่ยวข้องก่อนเปิดใหม่

[4] Restore NVIDIA profile from backup / คืนค่าโปรไฟล์จากไฟล์สำรอง
- แสดงรายการไฟล์ .nip ในโฟลเดอร์ backups
- ให้เลือกไฟล์ที่จะคืนค่า
- นำเข้าไฟล์สำรองที่เลือกด้วย -silentImport

[5] Open NVIDIA App / เปิด NVIDIA App
- พยายามเปิด NVIDIA App อัตโนมัติ
- ถ้าไม่พบ จะให้เปิดเองจากเมนู Start

[6] Open NVIDIA Control Panel / เปิด NVIDIA Control Panel
- พยายามเปิดด้วย nvcplui.exe
- ถ้าไม่สำเร็จ จะแจ้งให้เปิดเอง

[0] Exit / ออก
- ออกจากโปรแกรม

การคืนค่าจากไฟล์สำรอง
-----------------------
1) เข้าเมนู [4]
2) เลือกหมายเลขไฟล์สำรองที่ต้องการ
3) รอให้ระบบนำเข้าไฟล์สำรองเสร็จ

คำเตือนความปลอดภัย
---------------------
- ไม่ควรใช้ไฟล์ .nip แบบสุ่มจากอินเทอร์เน็ต หากไม่ทราบแหล่งที่มา
- ควรใช้เฉพาะไฟล์จากแหล่งที่เชื่อถือได้
- สคริปต์นี้ไม่ปรับแต่ง Global Profile โดยอัตโนมัติ
- สคริปต์นี้ไม่ปิด Defender, Windows Update, NVIDIA services หรือบริการความปลอดภัยของระบบ
