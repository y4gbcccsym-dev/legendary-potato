# เริ่มตรงนี้ ถ้าไม่ถนัดใช้คำสั่ง

ไฟล์นี้เป็นคู่มือแบบง่ายที่สุดสำหรับสร้าง `CornnerDesktopStudio.exe` บน Windows

## วิธีง่ายที่สุด

1. ดาวน์โหลดหรือ Clone repository นี้ลงเครื่องก่อน
2. แตกไฟล์ ZIP ถ้าดาวน์โหลดเป็น ZIP
3. เปิดโฟลเดอร์ที่แตกไฟล์แล้ว
4. มองหาไฟล์นี้:

```text
START_HERE.cmd
```

5. ดับเบิลคลิก `START_HERE.cmd`
6. ถ้ายังไม่มี .NET 8 SDK โปรแกรมจะแจ้งให้ติดตั้งก่อน
7. ถ้าทุกอย่างถูกต้อง ระบบจะ build, test, publish และเปิดโฟลเดอร์นี้ให้:

```text
publish\win-x64\
```

ไฟล์โปรแกรมจะอยู่ที่:

```text
publish\win-x64\CornnerDesktopStudio.exe
```

## สำคัญมาก

อย่าพิมพ์คำสั่งนี้ตามตัวอย่างแบบตรง ๆ:

```powershell
cd C:\path\to\legendary-potato
```

เพราะ `C:\path\to\legendary-potato` เป็นแค่ตัวอย่าง ไม่ใช่โฟลเดอร์จริงในเครื่องคุณ

ให้เข้าไปที่โฟลเดอร์จริงที่คุณดาวน์โหลดหรือแตก ZIP ไว้ เช่น:

```powershell
cd $env:USERPROFILE\Downloads\legendary-potato
```

หรือไม่ต้องพิมพ์คำสั่งเลย ให้ดับเบิลคลิก `START_HERE.cmd` จากในโฟลเดอร์ project

## ถ้าหาโฟลเดอร์ไม่เจอ

เปิด PowerShell แล้วรัน:

```powershell
Get-ChildItem $env:USERPROFILE -Filter START_HERE.cmd -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10 FullName
```

ถ้าไม่เจอ แปลว่ายังไม่ได้ดาวน์โหลดหรือแตกไฟล์ repository ลงเครื่อง

## ถ้าไม่มี .NET 8 SDK

ติดตั้ง .NET 8 SDK จาก Microsoft:

```text
https://dotnet.microsoft.com/download/dotnet/8.0
```

หลังติดตั้งเสร็จ ให้ปิด PowerShell เดิม เปิดใหม่ แล้วดับเบิลคลิก `START_HERE.cmd` อีกครั้ง
