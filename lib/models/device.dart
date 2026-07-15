/// Kayıtlı bir uydu alıcısını temsil eder.
class Device {
  final String id;
  String name;
  String host;
  int port;
  String? username;
  String? password;
  String? mac; // Wake-on-LAN için (opsiyonel)

  Device({
    required this.id,
    required this.name,
    required this.host,
    this.port = 80,
    this.username,
    this.password,
    this.mac,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'mac': mac,
      };

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] as String,
        name: j['name'] as String,
        host: j['host'] as String,
        port: (j['port'] as num?)?.toInt() ?? 80,
        username: j['username'] as String?,
        password: j['password'] as String?,
        mac: j['mac'] as String?,
      );
}
