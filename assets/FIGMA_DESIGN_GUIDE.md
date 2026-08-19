# KHOLO Figma Custom Design System Guide

এই গাইডের সাহায্যে আপনি Figma দিয়ে KHOLO অ্যাপের যেকোনো কালার, ফন্ট, বাটন, কার্ড এবং সম্পূর্ণ স্ক্রিনের ডিজাইন কাস্টমাইজ করতে পারবেন।

---

## ১. ফিগমাতে ডিজাইন টোকেন ইমপোর্ট করার নিয়ম (Figma Tokens Import)

আপনার ডেস্কটপে একটি **`KHOLO_Figma_Tokens.json`** ফাইল তৈরি করে দেওয়া হয়েছে:
📁 **ফাইল লোকেশন:** `C:\Users\Jain\Desktop\KHOLO_Figma_Tokens.json`

### যেভাবে ফিগমাতে ইমপোর্ট করবেন:
1. **Figma** ওপেন করুন।
2. Plugins এ গিয়ে **Tokens Studio for Figma** (বা Figma Variables) ওপেন করুন।
3. **Import** বাটনে ক্লিক করে `KHOLO_Figma_Tokens.json` ফাইলটি সিলেক্ট করুন।
4. সমস্ত ব্র্যান্ড কালার, ডার্ক মোড প্যালেট, টাইপোগ্রাফি এবং বর্ডার রেডিয়াস স্বয়ংক্রিয়ভাবে আপনার ফিগমা ফাইলে চলে আসবে!

---

## ২. অ্যাপের কোডে ডিজাইন ফাইলসমূহ (Code Mapping)

আপনি যখন ফিগমাতে কোনো পরিবর্তন করবেন, কোডের নিচের ফাইলগুলো পরিবর্তন করলেই সম্পূর্ণ অ্যাপের UI আপডেট হয়ে যাবে:

| ডিজাইনের অংশ | কোড ফাইল পাথ |
| :--- | :--- |
| **কালার ও থিম টোকেন** | `lib/app/theme/colors.dart` & `lib/app/theme/figma_tokens.dart` |
| **টাইপোগ্রাফি ও ফন্ট** | `lib/app/theme/typography.dart` |
| **কম্পোনেন্ট ও কার্ড থিম** | `lib/app/theme/theme.dart` |
| **হোম ও টুডে ড্যাশবোর্ড** | `lib/features/today/today_screen.dart` |
| **পিরিয়ড ও সাইকেল ট্র্যাকার** | `lib/features/cycle/cycle_screen.dart` |
| **বেবি কেয়ার ড্যাশবোর্ড** | `lib/features/baby/baby_screen.dart` |
| **AI স্কিন ডক্টর স্ক্যানার** | `lib/features/skin_scan/skin_scan_screen.dart` |
| **প্রেগন্যান্সি ট্র্যাকার** | `lib/features/pregnancy/pregnancy_screen.dart` |
| **শপ ও চেকআউট স্ক্রিন** | `lib/features/shop/shop_screen.dart` & `lib/features/checkout/checkout_screen.dart` |

---

## ৩. কালার পরিবর্তন করার সহজ নিয়ম

ফিগমাতে নতুন কোনো কালার পছন্দ হলে `lib/app/theme/colors.dart` ফাইলে হেক্স কোড পরিবর্তন করুন:

```dart
// উদাহরণ:
static const Color blush = Color(0xFFFFADEE);   // আপনার নতুন কালার হেক্স
static const Color wine = Color(0xFF92003A);    // আপনার নতুন ব্র্যান্ড কালার
```

বাকি সম্পূর্ণ অ্যাপ ডার্ক ও লাইট মোডে নিজে থেকেই নতুন কালার গ্রহণ করবে।
