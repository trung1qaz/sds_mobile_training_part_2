import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User{
  User({
    required this.taxCtrl,
    required this.userCtrl,
});
  @HiveField(0)
  int taxCtrl;

  @HiveField(1)
  String userCtrl;
}