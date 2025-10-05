# FloraSign AI - แอปพลิเคชันจดจำและแสดงข้อมูลดอกไม้

## 📖 คำอธิบายโครงการ

FloraSign AI เป็นแอปพลิเคชัน Flutter ที่ช่วยให้ผู้ใช้สามารถ:
- ดูข้อมูลดอกไม้ประจำวันเกิด (Birth Flowers)
- ดูข้อมูลดอกไม้ยอดนิยม (Popular Flowers)
- ถ่ายภาพดอกไม้และส่งไปยัง AI API เพื่อจำแนก
- บันทึกดอกไม้ที่ชื่นชอบ (Favorites)
- ดูรายละเอียดดอกไม้พร้อมความหมายสีต่างๆ

## 🏗️ โครงสร้างโปรเจค

```
lib/
├── main.dart                    # จุดเริ่มต้นแอป พร้อมการตรวจสอบฐานข้อมูล
├── start_screen.dart           # หน้าจอเริ่มต้น
├── home_screen.dart            # หน้าจอหลัก
├── birth_flowers_screen.dart   # หน้าจอดอกไม้ประจำวันเกิด
├── popular_flowers_screen.dart # หน้าจอดอกไม้ยอดนิยม
├── camera_screen.dart          # หน้าจอกล้องถ่ายภาพ
├── flower_detail_screen.dart   # หน้าจอรายละเอียดดอกไม้
├── favorites_screen.dart       # หน้าจอรายการโปรด (ไม่ได้ใช้งานในขณะนี้)
├── models/
│   └── flower.dart            # โมเดลข้อมูลดอกไม้
└── services/
    ├── database_helper.dart   # จัดการฐานข้อมูล SQLite
    └── favorites_service.dart # จัดการระบบรายการโปรด

asset/
├── data/
│   └── flowers.json          # ข้อมูลดอกไม้ (Simple Array Structure)
└── *.png                     # รูปภาพต่างๆ
```

## 🗄️ ระบบฐานข้อมูล

### ตาราง `flowers`
```sql
CREATE TABLE flowers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  day TEXT,                    -- วันในสัปดาห์ (เช่น วันจันทร์)
  nameThai TEXT NOT NULL,      -- ชื่อภาษาไทย
  nameEnglish TEXT NOT NULL,   -- ชื่อภาษาอังกฤษ
  imageUrl TEXT,               -- path ของรูปภาพ
  colorMeanings TEXT,          -- ความหมายของสีต่างๆ (JSON)
  otherMeanings TEXT,          -- ความหมายอื่นๆ
  useFor TEXT,                 -- การใช้งาน
  isFavorite INTEGER DEFAULT 0, -- สถานะรายการโปรด (0/1)
  imageBase64 TEXT,            -- ข้อมูลรูปภาพ Base64
  createdAt TEXT,
  updatedAt TEXT
);
```

### ตาราง `data_version` (ไม่ใช้แล้ว)
```sql
-- ตารางนี้ถูกสร้างขึ้นแต่ไม่ได้ใช้งานในระบบปัจจุบัน
CREATE TABLE data_version (
  id INTEGER PRIMARY KEY,
  json_version INTEGER NOT NULL,
  last_updated TEXT NOT NULL
);
```

## � ระบบจัดการข้อมูล

ระบบใช้โครงสร้าง JSON แบบง่าย:

1. **JSON Structure:**
```json
[
  {
    "day": "วันจันทร์",
    "nameThai": "ดอกมะลิ",
    "nameEnglish": "Jasmine",
    "imageUrl": "asset/mondayflower.png",
    "meanings": {
      "colorMeanings": null,
      "other": "ความบริสุทธิ์ ความรัก"
    },
    "useFor": ["ใช้ประดับ", "บูชาพระ"],
    "isFavorite": true
  }
]
```

2. **การอัปเดตข้อมูล:**
   - แก้ไข `flowers.json` โดยตรง (เพิ่ม/ลบ/แก้ไขดอกไม้)
   - ลบข้อมูลแอปหรือใช้ `clearAndReimportData()` เพื่อโหลดข้อมูลใหม่
   - รีสตาร์ทแอป

## 🎨 ระบบ Color Meanings

สำหรับดอกไม้ที่มีความหมายตามสี (เช่น กุหลาบ):

```json
"meanings": {
  "colorMeanings": [
    {
      "color": "สีแดง",
      "meaning": "ความรักแรงกล้า"
    },
    {
      "color": "สีขาว", 
      "meaning": "มิตรภาพ ความบริสุทธิ์"
    }
  ],
  "other": null
}
```

แอปจะแสดงเป็น badge สีพร้อมข้อความใน `flower_detail_screen.dart`

## 📱 หน้าจอหลัก

### หน้าจอที่ใช้งานได้:
- ✅ **Home Screen** - หน้าหลักพร้อมการนำทาง
- ✅ **Birth Flowers** - ดอกไม้ประจำวันเกิด
- ✅ **Popular Flowers** - ดอกไม้ยอดนิยม  
- ✅ **Camera** - ถ่ายภาพและส่งไปยัง API
- ✅ **Flower Detail** - รายละเอียดดอกไม้พร้อม Color Meanings
- ✅ **Favorites** - รายการโปรด (ปิดการใช้งานชั่วคราว)

### หน้าจอที่ปิดการใช้งาน:
- 🚫 **Favorites Button** - ปุ่มรายการโปรดในหน้าหลัก (commented out)
- 🚫 **Debug Button** - ปุ่มตรวจสอบฐานข้อมูล (commented out)

## 🔧 การติดตั้งและการพัฒนา

### ข้อกำหนดระบบ:
```yaml
dependencies:
  flutter: sdk: flutter
  sqflite: ^2.3.0        # ฐานข้อมูล SQLite
  path: ^1.8.3           # จัดการ path
  camera: ^0.10.5+5      # กล้องถ่ายภาพ
  image_picker: ^1.0.4   # เลือกรูปภาพ
```

### การเริ่มต้น:
1. Clone โปรเจค
2. รันคำสั่ง: `flutter pub get`
3. รันแอป: `flutter run`

## 🐛 การ Debug

### ใน `main.dart`:
```dart
// จะแสดงข้อมูลฐานข้อมูลที่ console เมื่อเริ่มแอป
print('=== MAIN.DART DATABASE DEBUG ===');
print('Database initialized successfully');
// แสดงดอกไม้ทั้งหมดพร้อม Color Meanings
```

### การเปิดใช้ Debug Button:
```dart
// ใน home_screen.dart ลบ comment ออกจาก:
// 1. imports (line 7-8)
// 2. _showDatabaseDebug method (line 20-85)  
// 3. Debug button widget (line 130-145)
```

## 📷 ระบบกล้อง

`camera_screen.dart` รองรับ:
- ถ่ายภาพใหม่
- เลือกจากแกลเลอรี่
- บันทึกรูปภาพ
- ส่งไปยัง `_sendImageToAPI()` ใน `home_screen.dart`

### API Integration (TODO):
```dart
// ใน _sendImageToAPI method
var request = http.MultipartRequest('POST', Uri.parse('YOUR_API_URL'));
request.files.add(await http.MultipartFile.fromPath('image', imagePath));
var response = await request.send();
```

## 📊 ระบบ Favorites

### การทำงาน:
1. ผู้ใช้สามารถเพิ่ม/ลบรายการโปรดใน `flower_detail_screen.dart`
2. ข้อมูลจะถูกบันทึกในฐานข้อมูล SQLite
3. `favorites_screen.dart` จะแสดงรายการโปรดทั้งหมด

### การเปิดใช้งาน:
```dart
// ใน home_screen.dart uncomment favorite button
// ลบ comment ออกจาก line 152-170
```

## 🔄 การอัปเดตข้อมูล

### เพิ่มดอกไม้ใหม่:
1. แก้ไข `asset/data/flowers.json` (เพิ่มดอกไม้ใหม่ในอาร์เรย์)
2. ลบข้อมูลแอป (Clear App Data) หรือใช้ Manual Refresh
3. รีสตาร์ทแอป - ระบบจะโหลดข้อมูลใหม่

### การอัปเดต Manual:
```dart
// ใช้ใน favorites_screen.dart หรือสร้างปุ่ม refresh
await _favoritesService.clearAndReimportData();
```

## 📝 Notes สำหรับนักพัฒนา

### สิ่งที่ทำงานแล้ว:
- ✅ ระบบฐานข้อมูล SQLite พร้อมการจัดการข้อมูล JSON แบบง่าย
- ✅ การแสดง Color Meanings แบบ dynamic
- ✅ ระบบ Favorites ครบถ้วน
- ✅ การถ่ายภาพและเตรียมส่ง API
- ✅ UI/UX ตามการออกแบบ

### สิ่งที่รอการพัฒนา:
- 🔄 API Integration สำหรับ AI recognition
- 🔄 Backend server connection
- 🔄 Image processing และ analysis

### การแก้ไขปัญหาที่พบ:
1. **Database ไม่อัปเดต**: ลบข้อมูลแอปและรีสตาร์ท
2. **Color Meanings ไม่แสดง**: ตรวจสอบ JSON structure
3. **รูปภาพไม่โหลด**: ตรวจสอบ path ใน asset folder

## 👥 Contact

สำหรับคำถามเพิ่มเติมหรือการพัฒนาต่อ กรุณาตรวจสอบ:
- Git branch: `database`
- Repository: `florasign_AI`
- Owner: `ParichatrSaipan`

---

