import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Transaction {
  // ID bisa int (SQLite) atau String (Firestore)
  final dynamic id;
  final String description;
  final double amount;
  final String category;
  final String type; // 'income' atau 'expense'
  final DateTime date;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      // Handle both int (SQLite) and String (Firestore) ID
      id: map['id'] is int 
          ? map['id'] as int 
          : map['id'] is String 
              ? map['id'] as String 
              : null,
      description: map['description']?.toString() ?? '',
      amount: (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : (map['amount'] is double)
              ? map['amount'] as double
              : double.tryParse(map['amount'].toString()) ?? 0.0,
      category: map['category']?.toString() ?? '',
      type: map['type']?.toString() ?? 'expense',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TransactionDatabase {
  static final TransactionDatabase instance = TransactionDatabase._init();
  static Database? _database;

  TransactionDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

void main() async {
  final db = TransactionDatabase.instance;

  // Insert contoh transaksi
  await db.insertTransaction(Transaction(
    description: 'Gaji Bulanan',
    amount: 5000000,
    category: 'Income',
    type: 'income',
    date: DateTime.now(),
  ));

  await db.insertTransaction(Transaction(
    description: 'Beli Makan',
    amount: 25000.5,
    category: 'Food',
    type: 'expense',
    date: DateTime.now(),
  ));

  // Ambil semua transaksi
  final transactions = await db.getAllTransactions();
  for (var t in transactions) {
    print(t.toMap());
  }

  await db.close();
}