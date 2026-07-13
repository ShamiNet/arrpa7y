// import { Request, Response } from 'express';
// import { User } from '../models/User.js';
// import { Wallet } from '../models/Wallet.js';
// import { InvestmentTrack, TrackType } from '../models/InvestmentTrack.js';
// import { Transaction } from '../models/Transaction.js'; 
// import * as fs from 'fs';
// import * as path from 'path';
// import { ShamCashService } from '../services/shamCashService.js';

// export class UserController {

//   public static async initiateShamCashDeposit(req: any, res: any): Promise<void> {
//     try {
//       const { walletId, amount, phone } = req.body;
//       const invoice = await ShamCashService.createDepositInvoice(walletId, amount, phone);
//       res.json({ success: true, invoice });
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async handleShamCashWebhook(req: any, res: any): Promise<void> {
//     try {
//       const { order_id, status, amount, phone_number } = req.body;
//       if (status === 'SUCCESS') {
//         const wallet = await Wallet.findById(order_id);
//         if (wallet) {
//           wallet.principalBalance += Number(amount);
//           await wallet.save();
//           await Transaction.create({
//             walletId: wallet._id,
//             type: 'DEPOSIT',
//             amount: Number(amount),
//             description: `إيداع آلي ناجح عبر بوابة شام كاش (هاتف: ${phone_number})`,
//             date: new Date()
//           });
//           console.log(`💵 [ShamCash]: تم شحن محفظة العميل بمبلغ ${amount} وتوليد السند المالي بنجاح.`);
//         } else {
//           console.log(`⚠️ [ShamCash]: استقبلنا دفعة ناجحة ولكن لم يتم العثور على محفظة بالـ ID: ${order_id}`);
//         }
//       }
//       res.status(200).send('OK');
//     } catch (error: any) {
//       console.error('❌ خطأ بداخل استقبال Webhook شام كاش:', error.message);
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async createClient(req: Request, res: Response): Promise<void> {
//     try {
//       const { name, role, trackType, initialPrincipal } = req.body;
//       if (!name || !trackType || initialPrincipal === undefined) {
//         res.status(400).json({ error: 'الرجاء إدخال الاسم، نوع المسار، ورأس المال التأسيسي.' });
//         return;
//       }
//       const track = await InvestmentTrack.findOne({ type: trackType });
//       if (!track) {
//         res.status(400).json({ error: 'مسار الاستثمار المحدد غير موجود.' });
//         return;
//       }
//       const newUser = await User.create({
//         name,
//         role: role || 'CLIENT',
//         email: `client_${Date.now()}@al-itqan.com`,
//         passwordHash: 'DUMMY_PASSWORD_HASH_FOR_CLIENTS'
//       });
//       const newWallet = await Wallet.create({
//         userId: newUser._id,
//         trackId: track._id,
//         principalBalance: Number(initialPrincipal),
//         totalProfitsEarned: 0
//       });
//       res.status(201).json({
//         message: '🚀 تم إنشاء المستثمر وتأسيس محفظته المالية بنجاح!',
//         user: newUser,
//         wallet: newWallet
//       });
//     } catch (error: any) {
//       res.status(500).json({ error: error.message || 'حدث خطأ أثناء إنشاء الحساب.' });
//     }
//   }

//   public static async getAllWallets(req: Request, res: Response): Promise<void> {
//     try {
//       const wallets = await Wallet.find().populate('userId').populate('trackId');
//       res.json(wallets);
//     } catch (error: any) {
//       res.status(500).json({ error: error.message || 'حدث خطأ أثناء جلب البيانات.' });
//     }
//   }

//   public static async getServerFiles(req: any, res: any): Promise<void> {
//     try {
//       const srcPath = path.join(process.cwd(), 'src');
//       const readDir = (dirPath: string): any[] => {
//         const files = fs.readdirSync(dirPath);
//         return files.map(file => {
//           const fullPath = path.join(dirPath, file);
//           const stat = fs.statSync(fullPath);
//           const relativePath = path.relative(path.join(process.cwd(), 'src'), fullPath);
//           return {
//             name: file,
//             path: relativePath,
//             isFolder: stat.isDirectory(),
//             children: stat.isDirectory() ? readDir(fullPath) : []
//           };
//         });
//       };
//       const fileTree = readDir(srcPath);
//       res.json({ tree: fileTree });
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async handleFileOperation(req: any, res: any): Promise<void> {
//     try {
//       const { filePath, action, content } = req.body;
//       if (!filePath) {
//         res.status(400).json({ error: 'مسار الملف مطلوب' });
//         return;
//       }
//       const safePath = path.join(process.cwd(), 'src', filePath);
//       if (!safePath.startsWith(path.join(process.cwd(), 'src'))) {
//         res.status(403).json({ error: 'غير مسموح بالوصول خارج مجلد src' });
//         return;
//       }
//       if (action === 'READ') {
//         if (!fs.existsSync(safePath)) {
//           res.status(404).json({ error: 'الملف غير موجود' });
//           return;
//         }
//         const fileContent = fs.readFileSync(safePath, 'utf8');
//         res.json({ content: fileContent });
//       } 
//       else if (action === 'WRITE') {
//         fs.writeFileSync(safePath, content ?? '', 'utf8');
//         res.json({ message: '🚀 تم حفظ وتحديث ملف السيرفر بنجاح!' });
//       } 
//       else {
//         res.status(400).json({ error: 'إجراء غير صالح' });
//       }
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async updateUser(req: any, res: any): Promise<void> {
//     try {
//       const { id } = req.params;
//       const { name, role, customCommissionRate } = req.body;

//       const user = await User.findById(id);
//       if (!user) {
//         res.status(404).json({ error: 'المستثمر غير موجود' });
//         return;
//       }

//       if (name) user.name = name;
//       if (role) user.role = role;
      
//       if (customCommissionRate !== undefined) {
//         user.customCommissionRate = customCommissionRate === null ? null : Number(customCommissionRate);
//       }

//       await user.save();
//       res.json({ message: '🚀 تم تحديث بيانات المستثمر بنجاح!', user });
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async deleteUser(req: any, res: any): Promise<void> {
//     try {
//       const { id } = req.params;

//       await Wallet.deleteMany({ userId: id });
//       const deletedUser = await User.findByIdAndDelete(id);

//       if (!deletedUser) {
//         res.status(404).json({ error: 'المستثمر غير موجود بالأساس' });
//         return;
//       }

//       res.json({ message: '🗑️ تم حذف المستثمر وتصفية محفظته من النظام نهائياً.' });
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }

//   public static async getShamCashBalances(req: any, res: any): Promise<void> {
//     try {
//       const balanceData = await ShamCashService.getMerchantBalances();
//       res.json(balanceData);
//     } catch (error: any) {
//       res.status(500).json({ error: error.message });
//     }
//   }
// }