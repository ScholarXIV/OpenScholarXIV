import 'package:hive/hive.dart';

class SpeechRateStore {
  static const boxName = "speedRateBox";
  static const key = "speedRate";
  static const defaultRate = 0.5;

  Future<double> load() async {
    final box = await Hive.openBox(boxName);
    final stored = box.get(key);
    await box.close();
    if (stored is num) {
      return stored.toDouble();
    }
    return defaultRate;
  }

  Future<void> save(double rate) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, rate);
    await box.close();
  }
}
