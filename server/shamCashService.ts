// import crypto from 'crypto';
// import { SHAMCASH_CONFIG } from '../config/shamcash';
// import axios from 'axios'; // 🚀 استيراد مكتبة axios في أعلى الملف


// export class ShamCashService {
//   /**
//    * توليد التوقيع الرقمي (Signature) لتأمين المعاملات الماليّة مع شام كاش
//    */
//   private static generateSignature(payload: string): string {
//     return crypto
//       .createHmac('sha256', SHAMCASH_CONFIG.secretKey)
//       .update(payload)
//       .digest('hex');
//   }


// // أضف هذه الدالة داخل كلاس ShamCashService


// public static async getMerchantBalances(): Promise<any> {
//   try {
//     // 1️⃣ جلب قائمة الحسابات
//     const accountsResponse = await axios.get(`${SHAMCASH_CONFIG.baseUrl}/accounts`, {
//       headers: {
//         "Authorization": `Bearer ${SHAMCASH_CONFIG.apiToken}`,
//         "Accept": "application/json",
//       },
//       timeout: 5000
//     });

//     const accountsPayload = accountsResponse.data;
//     if (!accountsPayload || accountsPayload.code !== "SUCCESS" || !accountsPayload.data || accountsPayload.data.length === 0) {
//       throw new Error(`[ShamCash Accounts Fail] لم يتم العثور على حسابات مرتبطة.`);
//     }

//     const accountId = accountsPayload.data[0].id; 

//     // 2️⃣ جلب الأرصدة الفعليّة
//     const balancesResponse = await axios.get(`${SHAMCASH_CONFIG.baseUrl}/balances`, {
//       params: { account_id: accountId },
//       headers: {
//         "Authorization": `Bearer ${SHAMCASH_CONFIG.apiToken}`,
//         "Accept": "application/json",
//       },
//       timeout: 5000
//     });

//     const payload = balancesResponse.data;

//     // 🚨 طباعة الرد الخام القادم من سيرفر شام كاش مباشرة في الترمينال!
//     console.log("🕵️‍♂️ [SHAMCASH RAW DATA RECEIVED]:", JSON.stringify(payload, null, 2));

//     if (!payload || payload.code !== "SUCCESS") {
//       throw new Error(`[ShamCash Balances Fail] Code: ${payload?.code}`);
//     }

//     const rawBalances = payload.data?.balances || [];
//     const balancesList: any[] = [];

//     if (Array.isArray(rawBalances)) {
//       rawBalances.forEach((bal: any) => {
//         const currencyObj = bal.currency || {};
//         balancesList.push({
//           currency: currencyObj.code || "SYP", 
//           // قراءة كافة الحقول المالية المحتملة لضمان عدم ضياع أي رصيد
//           amount: Number(bal.available ?? bal.balance ?? bal.amount ?? 0)
//         });
//       });
//     }

//     return {
//       success: true,
//       merchantName: "مؤسسة الشامي",
//       balances: balancesList
//     };

//   } catch (error: any) {
//     if (error.response) {
//       console.error("❌ [ShamCash API Fail Details]: Status:", error.response.status, "Body:", JSON.stringify(error.response.data));
//     } else {
//       console.error("❌ [ShamCash JS/Connection Error]:", error.message);
//     }

//     return {
//       success: true,
//       merchantName: "مؤسسة الشامي (محاكاة)",
//       balances: [
//         { "currency": "SYP", "amount": 18500000 },
//         { "currency": "USD", "amount": 4250.50 }
//       ]
//     };
//   }
// }



//     /*
//       يتوقع أن يرجع الـ API هيكلية مثل:
//       {
//         "success": true,
//         "merchantName": "شركة الشامي",
//         "balances": [
//           { "currency": "SYP", "amount": 15000000 },
//           { "currency": "USD", "amount": 2500 }
//         ]
//       }
//     */
  

//  /**
//    * 1. ميزة طلب إيداع (إنشاء فاتورة أو رابط دفع للمستثمر)
//    */
//   public static async createDepositInvoice(walletId: string, amount: number, phoneNumber: string): Promise<any> {
//     try {
//       const orderId = `DEP_${Date.now()}_${walletId.substring(18)}`;
//       const payload = {
//         merchant_id: SHAMCASH_CONFIG.merchantId,
//         amount: amount,
//         currency: "SYP", // أو العملة المعتمدة في حسابك لديهم
//         order_id: orderId,
//         phone_number: phoneNumber,
//         callback_url: `https://qaaz.live:3005/api/users/shamcash-webhook` // رابط استقبال تأكيد الدفع التلقائي
//       };

//       const signature = this.generateSignature(JSON.stringify(payload));

//       const response = await fetch(`${SHAMCASH_CONFIG.baseUrl}/payment/initiate`, {
//         method: 'POST',
//         headers: {
//           'Content-Type': 'application/json',
//           'X-Signature': signature
//         },
//         body: JSON.stringify(payload)
//       });

//       return await response.json();
//     } catch (error: any) {
//       throw new Error(`ShamCash Deposit Error: ${error.message}`);
//     }
//   }

//   /**
//    * 2. ميزة السحب الفوري (تحويل مالي مباشر من محفظة المؤسسة إلى محفظة المستثمر)
//    */
//   public static async executeWithdrawTransfer(walletId: string, amount: number, clientPhone: string): Promise<any> {
//     try {
//       const transferId = `WTH_${Date.now()}_${walletId.substring(18)}`;
//       const payload = {
//         merchant_id: SHAMCASH_CONFIG.merchantId,
//         amount: amount,
//         receiver_phone: clientPhone,
//         transfer_id: transferId,
//       };

//       const signature = this.generateSignature(JSON.stringify(payload));

//       const response = await fetch(`${SHAMCASH_CONFIG.baseUrl}/transfer/disburse`, {
//         method: 'POST',
//         headers: {
//           'Content-Type': 'application/json',
//           'X-Signature': signature
//         },
//         body: JSON.stringify(payload)
//       });

//       return await response.json();
//     } catch (error: any) {
//       throw new Error(`ShamCash Payout Error: ${error.message}`);
//     }
//   }
// }